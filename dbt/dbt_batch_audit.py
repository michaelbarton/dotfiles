#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["click", "mdformat"]
# ///
"""
dbt_batch_audit: run dbt model audits across multiple models and LLMs in
parallel, then synthesize a final consolidated report.

Accepts SQL file paths, directories, and shell globs. Model names are inferred
from filenames (e.g. models/int_orders.sql → int_orders).

Usage:
    # single files
    dbt_batch_audit.py models/int_orders.sql models/stg_users.sql ...

    # a whole directory
    dbt_batch_audit.py models/intermediate/

    # shell glob (expanded by the shell before the script sees it)
    dbt_batch_audit.py models/int_*.sql

    # mix and match
    dbt_batch_audit.py models/intermediate/ models/stg_special.sql
"""

import re
import subprocess
import sys
import glob
import os
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import click


def run(cmd, cwd=None, capture=False, check=True):
    result = subprocess.run(cmd, cwd=cwd, capture_output=capture, text=True)
    if check and result.returncode != 0:
        stderr = result.stderr.strip() if result.stderr else ""
        click.echo(
            f"ERROR: command failed (exit {result.returncode}): {' '.join(cmd)}",
            err=True,
        )
        if stderr:
            click.echo(stderr, err=True)
        sys.exit(result.returncode)
    return result


def compile_model(model_name, root):
    click.echo(f"  Compiling {model_name}...")
    run(["uv", "run", "dbt", "compile", "-s", model_name, "--quiet"], cwd=root)
    pattern = os.path.join(root, "target", "compiled", "**", f"{model_name}.sql")
    matches = glob.glob(pattern, recursive=True)
    if not matches:
        click.echo(f"ERROR: no compiled SQL found for {model_name}", err=True)
        sys.exit(1)
    with open(matches[0]) as f:
        return f.read()


def get_sample_rows(model_name, root, limit):
    click.echo(f"  Fetching sample rows for {model_name} (limit={limit})...")
    result = run(
        [
            "uv", "run", "dbt", "show", "-s", model_name,
            "--limit", str(limit), "--output", "json", "--log-format", "json",
        ],
        cwd=root,
        capture=True,
        check=False,
    )
    if result.returncode != 0:
        click.echo(f"  WARNING: dbt show failed for {model_name}", err=True)
        return "(dbt show failed)"
    return result.stdout.strip() or "(no rows returned)"


def write_context_file(output_dir, model_name, template, compiled_sql, sample_rows, source_sql):
    """Write the full audit context to a file so cursor-agent can read it."""
    ctx_dir = os.path.join(output_dir, ".context")
    os.makedirs(ctx_dir, exist_ok=True)

    # Substitute compiled_sql first to avoid the compiled SQL accidentally
    # containing the {{sample_rows}} placeholder.
    content = template.replace("{{compiled_sql}}", compiled_sql)
    content = content.replace("{{sample_rows}}", sample_rows)
    content += f"\n\nSource SQL:\n{source_sql}"

    ctx_path = os.path.join(ctx_dir, f"{model_name}__context.md")
    with open(ctx_path, "w") as f:
        f.write(content)
    return os.path.abspath(ctx_path)


def get_available_models():
    """Return the set of valid model IDs from cursor-agent --list-models."""
    result = subprocess.run(
        ["cursor-agent", "--list-models"],
        capture_output=True,
        text=True,
    )
    # Strip ANSI escape codes, then extract the first token of each line that
    # looks like a model ID (alphanumeric + hyphens/dots, before the " - " separator).
    ansi_escape = re.compile(r"\x1b\[[0-9;]*[A-Za-z]|\x1b\[[0-9]*[A-Za-z]")
    clean = ansi_escape.sub("", result.stdout)
    models = set()
    for line in clean.splitlines():
        m = re.match(r"^([a-zA-Z0-9][a-zA-Z0-9._-]+)\s+-\s+", line.strip())
        if m:
            models.add(m.group(1))
    return models


def validate_llms(llms):
    """Fail fast if any requested LLM is not in cursor-agent's available models."""
    click.echo("Validating model names against cursor-agent...")
    available = get_available_models()
    if not available:
        click.echo(
            "WARNING: could not retrieve available models list; skipping validation",
            err=True,
        )
        return
    invalid = [llm for llm in llms if llm not in available]
    if invalid:
        click.echo(
            f"ERROR: the following model(s) are not available in cursor-agent:\n"
            + "\n".join(f"  - {m}" for m in invalid)
            + f"\n\nAvailable models:\n  " + "\n  ".join(sorted(available)),
            err=True,
        )
        sys.exit(1)
    click.echo(f"  All {len(llms)} model(s) validated OK.\n")


def run_audit(model_name, context_path, llm, output_dir, root):
    click.echo(f"  [{model_name} × {llm}] Starting audit...")
    start = time.monotonic()

    prompt = (
        f"Read the audit instructions and dbt model context from {context_path}. "
        "Perform a thorough data quality audit of the dbt model as described. "
        "Output your complete findings as a well-structured markdown report."
    )

    try:
        result = subprocess.run(
            ["cursor-agent", "--print", "--force", "--model", llm, prompt],
            capture_output=True,
            text=True,
            cwd=root,
            timeout=900,
        )
    except subprocess.TimeoutExpired:
        report = "(audit timed out after 900s)"
        click.echo(f"  [{model_name} × {llm}] Timed out", err=True)
        safe_llm = llm.replace("/", "_").replace(" ", "_")
        report_path = os.path.join(output_dir, f"{model_name}__{safe_llm}.md")
        with open(report_path, "w") as f:
            f.write(f"# Audit: {model_name} (LLM: {llm})\n\n{report}\n")
        elapsed = time.monotonic() - start
        click.echo(f"  [{model_name} × {llm}] Done ({elapsed:.0f}s) → {report_path}")
        return model_name, llm, report

    if result.returncode == 0:
        report = result.stdout.strip()
    else:
        report = f"(audit failed: exit {result.returncode})\n{result.stderr}"

    safe_llm = llm.replace("/", "_").replace(" ", "_")
    report_path = os.path.join(output_dir, f"{model_name}__{safe_llm}.md")
    with open(report_path, "w") as f:
        f.write(f"# Audit: {model_name} (LLM: {llm})\n\n{report}\n")

    elapsed = time.monotonic() - start
    click.echo(f"  [{model_name} × {llm}] Done ({elapsed:.0f}s) → {report_path}")
    return model_name, llm, report


def synthesize_reports(reports, synthesis_model, output_dir, root):
    click.echo("\nSynthesizing final report...")
    start = time.monotonic()

    combined_parts = []
    for model_name, llm, report in reports:
        combined_parts.append(
            f"---\n## Model: {model_name} | Reviewer: {llm}\n\n{report}\n"
        )
    combined_text = "\n".join(combined_parts)

    combined_path = os.path.join(output_dir, "all_individual_reports.md")
    with open(combined_path, "w") as f:
        f.write(f"# All Individual Audit Reports\n\n{combined_text}\n")

    # Write synthesis context to a file to avoid command-line length limits
    ctx_dir = os.path.join(output_dir, ".context")
    os.makedirs(ctx_dir, exist_ok=True)
    synthesis_ctx_path = os.path.abspath(
        os.path.join(ctx_dir, "synthesis_context.md")
    )

    synthesis_instructions = f"""\
You are a senior analytics engineer reviewing multiple dbt model audit reports.
Each report below was generated by a different LLM auditing a dbt model.

Your job:
1. Cross-reference findings across models and reviewers
2. Identify the most critical issues that appear consistently
3. Flag any contradictions between reviewers
4. Prioritize recommendations by impact and effort
5. Produce a final consolidated report in markdown

A key part of your analysis is **cross-model bug propagation**: for every significant finding in any
model, explicitly trace its downstream consequences through the model dependency chain. Ask: which
downstream models consume this model's output? If this bug is present in the data, what does that
mean for each downstream model's correctness? Does the bug amplify, get filtered out, or silently
corrupt aggregations further down the chain? Call out cases where a bug in an upstream model makes
a downstream model's output untrustworthy even if the downstream model itself has no defects.

Generate a final synthesis report with:
- An executive summary
- Critical findings (agreed upon by multiple reviewers or clearly valid), each with an explicit
  **Downstream impact** sub-section tracing the bug through the dependency chain
- A dependency propagation map: a table or diagram showing which bugs flow into which downstream
  models and what the compounded effect is
- Model-specific recommendations ordered by severity
- Cross-model patterns or systemic issues
- A prioritized action plan table, where items that fix root-cause bugs affecting multiple
  downstream models are ranked higher than equivalent-effort fixes that are locally scoped

---

Individual audit reports:

{combined_text}"""

    with open(synthesis_ctx_path, "w") as f:
        f.write(synthesis_instructions)

    prompt = (
        f"Read the synthesis instructions and individual audit reports from "
        f"{synthesis_ctx_path}. Follow the instructions to produce a final "
        "consolidated synthesis report in markdown."
    )

    try:
        result = subprocess.run(
            ["cursor-agent", "--print", "--force", "--model", synthesis_model, prompt],
            capture_output=True,
            text=True,
            cwd=root,
            timeout=1200,
        )
    except subprocess.TimeoutExpired:
        synthesis = "(synthesis timed out after 1200s)"
        click.echo("WARNING: synthesis timed out", err=True)
        synthesis_path = os.path.join(output_dir, "final_synthesis.md")
        with open(synthesis_path, "w") as f:
            f.write(f"# dbt Model Audit — Final Synthesis\n\n{synthesis}\n")
        return synthesis_path

    if result.returncode == 0:
        synthesis = result.stdout.strip()
    else:
        synthesis = (
            f"(synthesis failed: exit {result.returncode})\n{result.stderr}"
        )

    synthesis_path = os.path.join(output_dir, "final_synthesis.md")
    with open(synthesis_path, "w") as f:
        f.write(f"# dbt Model Audit — Final Synthesis\n\n{synthesis}\n")

    elapsed = time.monotonic() - start
    click.echo(f"Final synthesis ({elapsed:.0f}s) → {synthesis_path}")
    click.echo(f"Combined reports → {combined_path}")
    return synthesis_path


def resolve_sql_paths(paths):
    """Expand directories and verify that every path is a .sql file."""
    resolved = []
    for p in paths:
        p = os.path.abspath(p)
        if os.path.isdir(p):
            children = sorted(
                f for f in glob.glob(os.path.join(p, "**", "*.sql"), recursive=True)
            )
            if not children:
                click.echo(f"WARNING: no .sql files found in {p}", err=True)
            resolved.extend(children)
        elif os.path.isfile(p):
            if not p.endswith(".sql"):
                click.echo(f"ERROR: not a .sql file: {p}", err=True)
                sys.exit(1)
            resolved.append(p)
        else:
            click.echo(f"ERROR: path not found: {p}", err=True)
            sys.exit(1)
    return resolved


def model_name_from_path(filepath):
    return os.path.splitext(os.path.basename(filepath))[0]


@click.command()
@click.argument("paths", nargs=-1, required=True)
@click.option(
    "--llm", "llms", required=True, multiple=True,
    help="LLM model name for cursor-agent (repeatable)",
)
@click.option("--root", required=True, help="Path to dbt project root")
@click.option("--prompt", required=True, help="Path to the prompt template .md file")
@click.option(
    "--output-dir", default="./audit_reports", show_default=True,
    help="Directory for output reports",
)
@click.option("--limit", default=20, show_default=True, help="Row limit for dbt show")
@click.option(
    "--synthesis-model", default="sonnet-4.6-thinking", show_default=True,
    help="LLM for the final synthesis step",
)
@click.option(
    "--concurrency", default=3, show_default=True,
    help="Max parallel cursor-agent invocations",
)
def main(paths, llms, root, prompt, output_dir, limit, synthesis_model, concurrency):
    """Run dbt model audits across multiple models and LLMs, then synthesize.

    PATHS are .sql files, directories containing .sql files, or shell globs.
    Model names are inferred from filenames (int_orders.sql → int_orders).
    """
    validate_llms(llms + (synthesis_model,))

    sql_files = resolve_sql_paths(paths)
    if not sql_files:
        click.echo("ERROR: no .sql files resolved from the given paths", err=True)
        sys.exit(1)

    model_specs = []
    seen = set()
    for filepath in sql_files:
        name = model_name_from_path(filepath)
        if name in seen:
            click.echo(
                f"ERROR: duplicate model name '{name}' from {filepath}", err=True,
            )
            sys.exit(1)
        seen.add(name)
        model_specs.append((name, filepath))

    if not os.path.exists(prompt):
        click.echo(f"ERROR: prompt template not found: {prompt}", err=True)
        sys.exit(1)
    with open(prompt) as f:
        template = f.read()

    root = os.path.abspath(root)
    output_dir = os.path.abspath(output_dir)
    os.makedirs(output_dir, exist_ok=True)

    total = len(model_specs) * len(llms)
    click.echo(
        f"Auditing {len(model_specs)} model(s) × {len(llms)} LLM(s) = {total} audit(s)"
    )
    click.echo(f"Concurrency: {concurrency} | Synthesis model: {synthesis_model}\n")

    context_paths = {}
    for name, filepath in model_specs:
        click.echo(f"Preparing {name}...")
        compiled_sql = compile_model(name, root)
        sample_rows = get_sample_rows(name, root, limit)
        with open(filepath) as f:
            source_sql = f.read()
        context_paths[name] = write_context_file(
            output_dir, name, template, compiled_sql, sample_rows, source_sql,
        )

    click.echo(f"\nAll models compiled. Launching {total} audit(s)...\n")

    reports = []
    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        futures = {}
        for name, _ in model_specs:
            for llm in llms:
                fut = pool.submit(
                    run_audit, name, context_paths[name], llm, output_dir, root,
                )
                futures[fut] = (name, llm)

        for fut in as_completed(futures):
            name, llm = futures[fut]
            try:
                reports.append(fut.result())
            except Exception as e:
                click.echo(f"  ERROR [{name} × {llm}]: {e}", err=True)
                reports.append((name, llm, f"(error: {e})"))

    reports.sort(key=lambda r: (r[0], r[1]))

    synthesize_reports(reports, synthesis_model, output_dir, root)

    md_files = glob.glob(os.path.join(output_dir, "*.md"))
    if md_files:
        click.echo(f"\nFormatting {len(md_files)} markdown file(s)...")
        run(
            ["uvx", "mdformat", "--wrap", "100"] + md_files,
            cwd=root,
        )

    click.echo(f"\nDone! {len(reports)} audit(s) completed. Reports in: {output_dir}")


if __name__ == "__main__":
    main()
