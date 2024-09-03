#!/usr/bin/env python3

import subprocess
import sys
import json
from pathlib import Path
from typing import List, Dict

CONFIG_FILE = Path.home() / ".config/git/autocommit.json"
DEFAULT_CONFIG = {
    "auto_commit_files": ["CHANGELOG.md", "README.md"],
    "fallback_command": "git commit -a",
}


def run_command(command: str, interactive: bool = False) -> str:
    """Run a shell command and return its output if not interactive.

    Args:
        command: The shell command to run.
        interactive: Whether the command requires an interactive terminal.

    Returns:
        The output of the command as a string.

    Raises:
        SystemExit: If the command fails and check is True.
    """
    try:
        if interactive:
            subprocess.run(command, check=True, shell=True)
            return ""
        else:
            result = subprocess.run(command, capture_output=True, text=True, check=True, shell=True)
            return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {command}")
        if not interactive:
            print(f"Error message: {e.stderr.strip()}")
        sys.exit(1)


def load_config() -> Dict[str, List[str]]:
    """Load configuration from file or return default.

    Returns:
        The configuration as a dictionary.
    """
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            return json.load(f)
    return DEFAULT_CONFIG


def get_changed_files() -> List[Path]:
    """Get list of changed files.

    Returns:
        A list of Paths representing changed files.
    """
    output = run_command("git diff --name-only")
    return [Path(file) for file in output.splitlines() if file]


def only_specific_files_changed(specific_files: List[str], changed_files: List[Path]) -> bool:
    """Check if only specified files are changed.

    Args:
        specific_files: A list of specific filenames to check.
        changed_files: A list of Paths representing changed files.

    Returns:
        True if only specific files are changed, False otherwise.
    """
    return set(changed_files).issubset(set(Path(file) for file in specific_files))


def auto_commit(changed_files: List[Path]) -> None:
    """Auto commit the specified files with a generated commit message.

    Args:
        changed_files: A list of Paths representing files to be committed.
    """
    commit_message = " and ".join(f"Update {file.name}" for file in changed_files)
    run_command(f"git add {' '.join(map(str, changed_files))}")
    run_command(f'git commit -m "{commit_message}"')
    print(f"Autocommitted: {commit_message}")


def fallback_commit(command: str) -> None:
    """Run the fallback commit command.

    Args:
        command: The fallback command to run.
    """
    run_command(command, interactive=True)
    print("Used fallback command for commit.")


def main() -> None:
    """Main function to execute the git auto-commit script."""
    config = load_config()

    if "--config" in sys.argv:
        print("Current configuration:")
        print(json.dumps(config, indent=2))
        print(f"\nTo modify, edit {CONFIG_FILE}")
        return

    changed_files = get_changed_files()
    if not changed_files:
        print("No changes to commit.")
        return

    if only_specific_files_changed(config["auto_commit_files"], changed_files):
        auto_commit(changed_files)
    else:
        fallback_commit(config["fallback_command"])


if __name__ == "__main__":
    main()
