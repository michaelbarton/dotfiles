#!/usr/bin/env python3
"""View a single row from a JSONL file in a Pachyderm repository.

This script provides functionality to fetch files from a Pachyderm repository.
It allows users to select specific files using glob patterns, extract rows from
these files based on a glob pattern, automatically detect and decompress content
if compressed, and pretty-print JSON data.

The script uses the `pachctl` command-line tool to interact with Pachyderm and
supports decompression of zstandard and gzip compressed files.
"""

import argparse
import gzip
import re
import subprocess
import sys


import rich
import zstandard

SKIP_HEADER = 1
FILE_COLUMN = 1


def run_command(command: list[str]) -> str:
    """Execute a shell command and return its output.

    Args:
        command: The command to execute as a list of strings.

    Returns:
        str: The output of the command.

    Raises:
        SystemExit: If the command execution fails.
    """
    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        sys.exit(1)


def decompress_content(content: bytes, file_name: str) -> str:
    """
    Decompress content based on the file extension.

    Args:
        content (bytes): The content to decompress.
        file_name (str): The name of the file, used to determine the compression method.

    Returns:
        str: The decompressed content as a string.
    """
    if file_name.endswith(".zst"):
        dctx = zstandard.ZstdDecompressor()
        return dctx.decompress(content).decode("utf-8")
    elif file_name.endswith(".gz"):
        return gzip.decompress(content).decode("utf-8")
    else:
        return content.decode("utf-8")


def find_matching_row(lines: list[str], pattern: str) -> str | None:
    """
    Find the first row that matches the given glob pattern.

    Args:
        lines: List of strings to search through.
        pattern: Glob pattern to match against.

    Returns:
        The first matching row, or None if no match is found.
    """
    regex_pattern = re.compile(pattern.replace("*", ".*").replace("?", "."))
    for line in lines:
        if regex_pattern.search(line):
            return line
    return None


def main() -> None:
    """Main function to process Pachyderm repository files.

    This function parses command-line arguments, retrieves file content from
    a Pachyderm repository, decompresses it if necessary, selects a row based
    on a glob pattern, and pretty-prints the result if it's valid JSON.

    Command-line Arguments:
        repo_name (str): Name of the Pachyderm repository.
        --file-glob (str, optional): Glob pattern to select specific files. Defaults to "*".
        --row-glob (str, optional): Glob pattern to select a specific row. Defaults to "*".

    Raises:
        SystemExit: If an error occurs during execution.
    """
    parser = argparse.ArgumentParser(description="Process files from a Pachyderm repository.")
    parser.add_argument("repo_name", help="Name of the Pachyderm repository")
    parser.add_argument(
        "--file-glob", help="Glob pattern to select specific files (default: *)", default="*"
    )
    parser.add_argument(
        "--row-glob", help="Glob pattern to select a specific row (default: *)", default="*"
    )
    args = parser.parse_args()

    repo_name: str = args.repo_name
    file_glob: str = args.file_glob
    row_glob: str = args.row_glob

    # Fetch the files from the specified repository using the provided glob pattern
    glob_command = ["pachctl", "glob", "file", f"{repo_name}@master:{file_glob}"]
    glob_output = run_command(glob_command)

    if not glob_output:
        print(f"No files found in repository: {repo_name} with glob pattern: {file_glob}")
        sys.exit(1)

    # Select the first file if multiple files are returned
    file_name = glob_output.split("\n")[SKIP_HEADER].split("\t")[FILE_COLUMN]

    repo_path = f"{repo_name}@master:/{file_name}"

    # Extract the contents using pachctl
    get_file_command = ["pachctl", "get", "file", repo_path]
    try:
        file_content = subprocess.check_output(get_file_command)
    except subprocess.CalledProcessError as e:
        print(f"Error getting file content: {e}")
        sys.exit(1)

    # Decompress the content if necessary
    decompressed_content = decompress_content(file_content, file_name)

    # Split into lines
    lines: list[str] = decompressed_content.splitlines()

    # Find the first matching row
    matching_row = find_matching_row(lines, row_glob)

    if matching_row:
        rich.print_json(matching_row)
    else:
        print(f"No row matching the pattern '{row_glob}' was found in the file.")


if __name__ == "__main__":
    main()
