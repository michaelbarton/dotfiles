#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["click"]
# ///
"""
dbt_analyse: compile a dbt model, gather context, then launch an interactive
cursor-agent session. Designed to be called from a tmux window.

Usage:
    dbt_analyse.py --model <name> --root <dbt_project_root> \
                   --filepath <source_sql_path> --prompt <prompt_template_path>
"""

import subprocess
import sys
import glob
import os
import tempfile

import click


def run(cmd, cwd=None, capture=False, check=True):
    result = subprocess.run(
        cmd,
        cwd=cwd,
        capture_output=capture,
        text=True,
    )
    if check and result.returncode != 0:
        stderr = result.stderr.strip() if result.stderr else ""
        click.echo(f"ERROR: command failed (exit {result.returncode}): {' '.join(cmd)}", err=True)
        if stderr:
            click.echo(stderr, err=True)
        sys.exit(result.returncode)
    return result


@click.command()
@click.option("--model", required=True, help="dbt model name (no extension)")
@click.option("--root", required=True, help="Path to dbt project root")
@click.option("--filepath", required=True, help="Absolute path to the source SQL file")
@click.option("--prompt", required=True, help="Path to the prompt template .md file")
@click.option("--limit", default=20, show_default=True, help="Row limit for dbt show")
@click.option(
    "--model-flag", default="sonnet-4.6-thinking", show_default=True, help="cursor-agent model"
)
def main(model, root, filepath, prompt, limit, model_flag):
    # --- 1. compile ---
    click.echo(f"Compiling {model}...")
    run(["uv", "run", "dbt", "compile", "-s", model, "--quiet"], cwd=root)

    # --- 2. find compiled SQL ---
    pattern = os.path.join(root, "target", "compiled", "**", f"{model}.sql")
    matches = glob.glob(pattern, recursive=True)
    if not matches:
        click.echo(f"ERROR: no compiled SQL found for {model} — did compile succeed?", err=True)
        sys.exit(1)
    with open(matches[0]) as f:
        compiled_sql = f.read()
    click.echo(f"Compiled SQL: {matches[0]}")

    # --- 3. sample rows ---
    click.echo(f"Fetching sample rows (limit={limit})...")
    result = run(
        [
            "uv",
            "run",
            "dbt",
            "show",
            "-s",
            model,
            "--limit",
            str(limit),
            "--output",
            "json",
            "--log-format",
            "json",
        ],
        cwd=root,
        capture=True,
        check=False,
    )
    if result.returncode != 0:
        click.echo(
            f"WARNING: dbt show failed (exit {result.returncode}), continuing without sample rows",
            err=True,
        )
        sample_rows = "(dbt show failed)"
    else:
        sample_rows = result.stdout.strip() or "(no rows returned)"

    # --- 4. source SQL ---
    if not os.path.exists(filepath):
        click.echo(f"ERROR: source file not found: {filepath}", err=True)
        sys.exit(1)
    with open(filepath) as f:
        source_sql = f.read()

    # --- 5. build prompt ---
    if not os.path.exists(prompt):
        click.echo(f"ERROR: prompt template not found: {prompt}", err=True)
        sys.exit(1)
    with open(prompt) as f:
        template = f.read()
    # Substitute compiled_sql first; use a sentinel to avoid the compiled SQL
    # accidentally containing the {{sample_rows}} placeholder.
    full_prompt = template.replace("{{compiled_sql}}", compiled_sql)
    full_prompt = full_prompt.replace("{{sample_rows}}", sample_rows)
    full_prompt += f"\n\nSource SQL:\n{source_sql}"

    # --- 6. write context to a temp file & launch cursor-agent ---
    # Avoids OS arg-length limits (ARG_MAX) when compiled SQL + sample rows
    # are large.
    ctx = tempfile.NamedTemporaryFile(
        mode="w", suffix=".md", prefix=f"dbt_audit_{model}_", delete=False,
    )
    ctx.write(full_prompt)
    ctx.close()
    click.echo(f"Context written to {ctx.name}")

    click.echo(f"Launching cursor-agent ({model_flag})...")
    agent_prompt = (
        f"Read the audit instructions and dbt model context from {ctx.name}. "
        "Perform a thorough data quality audit of the dbt model as described."
    )
    os.execlp("cursor-agent", "cursor-agent", "--model", model_flag, agent_prompt)


if __name__ == "__main__":
    main()
