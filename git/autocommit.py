#!/usr/bin/env python3

import subprocess
import sys
import json
import argparse
from pathlib import Path

CONFIG_FILE = Path.home() / ".config/git/autocommit.json"

def run_command(command, check=True):
    """Run a shell command and return its output."""
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=check, shell=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        if check:
            print(f"Error executing command: {command}")
            print(f"Error message: {e.stderr.strip()}")
            sys.exit(1)
        return e.stderr.strip()

def load_config():
    """Load configuration from file or return default."""
    default_config = {
        "auto_commit_files": ["CHANGELOG.md", "README.md"],
        "fallback_command": "git commit -a"
    }
    if CONFIG_FILE.exists():
        return json.loads(CONFIG_FILE.read_text())
    return default_config

def get_changed_files():
    """Get list of changed files."""
    return [Path(file) for file in run_command("git diff --name-only").split("\n") if file]

def only_specific_files_changed(specific_files, changed_files):
    """Check if only specified files are changed."""
    return set(changed_files).issubset(set(Path(file) for file in specific_files))

def main(args):
    config = load_config()

    if args.config:
        print("Current configuration:")
        print(json.dumps(config, indent=2))
        print(f"\nTo modify, edit {CONFIG_FILE}")
        return

    # Check if there are any changes
    changed_files = get_changed_files()
    if not changed_files:
        print("No changes to commit.")
        return

    # Check if only specified files are changed
    if only_specific_files_changed(config["auto_commit_files"], changed_files):
        commit_message_parts = [f"Update {file.name}" for file in changed_files]
        commit_message = " and ".join(commit_message_parts)

        # Perform the commit
        run_command(f"git add {' '.join(str(file) for file in changed_files)}")
        run_command(f'git commit -m "{commit_message}"')
        print(f"Autocommitted: {commit_message}")
    else:
        # If other files are changed, use the fallback command
        run_command(config["fallback_command"], check=False)
        print("Used fallback command for commit.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Git auto-commit script with configurable options.")
    parser.add_argument("--config", action="store_true", help="Display current configuration")
    args = parser.parse_args()

    main(args)
