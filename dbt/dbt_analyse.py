#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["click", "pyyaml"]
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
import re
import tempfile

import click
import yaml


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


def get_lineage(model, root):
    """Return a summary of immediate parents and children from dbt ls."""
    lines = []
    for direction, selector in [
        ("parents", f"+{model},1+{model}"),
        ("children", f"{model}+,{model}1+"),
    ]:
        result = subprocess.run(
            ["uv", "run", "dbt", "ls", "-s", selector, "--output", "name", "--quiet"],
            capture_output=True,
            text=True,
            cwd=root,
        )
        if result.returncode == 0:
            names = [
                n.strip()
                for n in result.stdout.strip().splitlines()
                if n.strip() and n.strip() != model
            ]
            if names:
                lines.append(f"**{direction.title()}:** {', '.join(names)}")
    return "\n".join(lines) if lines else ""


def get_existing_tests(model, root):
    """Extract test definitions for a model from schema.yml files."""
    unique_files = glob.glob(os.path.join(root, "**", "*.yml"), recursive=True)

    tests = []
    for schema_path in unique_files:
        try:
            with open(schema_path) as f:
                doc = yaml.safe_load(f)
        except (yaml.YAMLError, OSError):
            continue
        if not isinstance(doc, dict):
            continue
        for m in doc.get("models", []):
            if not isinstance(m, dict) or m.get("name") != model:
                continue
            # Model-level tests
            for t in m.get("tests", []):
                tests.append(f"- model-level: {t}")
            # Column-level tests
            for col in m.get("columns", []):
                if not isinstance(col, dict):
                    continue
                col_name = col.get("name", "?")
                for t in col.get("tests", []):
                    if isinstance(t, str):
                        tests.append(f"- {col_name}: {t}")
                    elif isinstance(t, dict):
                        tests.append(f"- {col_name}: {t}")
    return "\n".join(tests) if tests else ""


def render_template(template, replacements):
    """Replace template placeholders, handling conditional {{#if}}/{{^if}} blocks."""
    for key, value in replacements.items():
        # Handle {{#if key}}...{{/if}} blocks
        if_pattern = re.compile(
            r"\{\{#if " + re.escape(key) + r"\}\}(.*?)\{\{/if\}\}",
            re.DOTALL,
        )
        not_pattern = re.compile(
            r"\{\{\^if " + re.escape(key) + r"\}\}(.*?)\{\{/if\}\}",
            re.DOTALL,
        )
        if value:
            template = if_pattern.sub(r"\1", template)
            template = not_pattern.sub("", template)
        else:
            template = if_pattern.sub("", template)
            template = not_pattern.sub(r"\1", template)
        # Replace the simple placeholder
        template = template.replace("{{" + key + "}}", value)
    return template


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

    # --- 5. gather lineage and existing tests ---
    click.echo("Gathering model lineage...")
    lineage = get_lineage(model, root)

    click.echo("Scanning for existing dbt tests...")
    existing_tests = get_existing_tests(model, root)

    # --- 6. build prompt ---
    if not os.path.exists(prompt):
        click.echo(f"ERROR: prompt template not found: {prompt}", err=True)
        sys.exit(1)
    with open(prompt) as f:
        template = f.read()

    full_prompt = render_template(
        template,
        {
            "compiled_sql": compiled_sql,
            "sample_rows": sample_rows,
            "existing_tests": existing_tests,
            "lineage": lineage,
            "data_profile": "",
        },
    )
    full_prompt += f"\n\nSource SQL:\n{source_sql}"

    # --- 7. write context to a temp file & launch cursor-agent ---
    ctx = tempfile.NamedTemporaryFile(
        mode="w",
        suffix=".md",
        prefix=f"dbt_audit_{model}_",
        delete=False,
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
