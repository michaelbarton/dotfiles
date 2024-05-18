#!/opt/homebrew/bin/python3
"""
Script to extract code from a Dockerized Python Poetry project directory and save it into a single text file.

This script allows you to extract code from a project directory and its subdirectories, as well as
additional specified directories and files. The extracted code is saved into a single text file.

You can customize the file extensions to include in the extraction process, as well as exclude specific
directories and files from being extracted.

The output file will contain the code from each extracted file, separated by a header indicating the file path.

Usage:
    python extract_code.py [OPTIONS]

Options:
    --root-dir TEXT             The root directory of the project. Defaults to the current directory.
    --output-file TEXT          The output text file where the code will be saved. Defaults to 'out/project_code_combined.txt'.
    --include-extensions TEXT   Comma-separated list of file extensions to include in the extraction. Defaults to '.py,.sh,.toml,.md'.
    --additional-dirs TEXT      Comma-separated list of additional directories to include. Defaults to an empty list.
    --additional-files TEXT     Comma-separated list of additional individual files to include. Defaults to an empty list.
    --exclude-dirs TEXT         Comma-separated list of directories to exclude from the extraction. Defaults to an empty list.
    --exclude-files TEXT        Comma-separated list of individual files to exclude from the extraction. Defaults to an empty list.
    --help                      Show this message and exit.
"""

import os
import click
import logging
from typing import List, Optional

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")


def validate_directory(ctx: click.Context, param: click.Parameter, value: str) -> str:
    """Validate that the directory exists.

    Args:
        ctx: The click context.
        param: The click parameter.
        value: The directory path.

    Returns:
        The validated directory path.

    Raises:
        click.BadParameter: If the directory does not exist.
    """
    if value and not os.path.isdir(value):
        raise click.BadParameter(f"Directory '{value}' does not exist.")
    return value


def validate_file(ctx: click.Context, param: click.Parameter, value: str) -> str:
    """Validate that the file path is valid or the file doesn't exist yet.

    Args:
        ctx: The click context.
        param: The click parameter.
        value: The file path.

    Returns:
        The validated file path.

    Raises:
        click.BadParameter: If the provided path is a directory.
    """
    if value and os.path.isdir(value):
        raise click.BadParameter("Please provide a valid file path, not a directory.")
    return value


def validate_extensions(ctx: click.Context, param: click.Parameter, value: str) -> List[str]:
    """Ensure extensions are provided correctly.

    Args:
        ctx: The click context.
        param: The click parameter.
        value: The comma-separated list of file extensions.

    Returns:
        The list of validated file extensions.

    Raises:
        click.BadParameter: If no file extensions are provided or if an extension doesn't start with a '.' character.
    """
    if not value:
        raise click.BadParameter("You must specify at least one file extension.")
    extensions = value.split(",")
    for ext in extensions:
        if ext and not ext.startswith("."):
            raise click.BadParameter("File extensions must start with a '.' character.")
    return extensions


def validate_additional_paths(ctx: click.Context, param: click.Parameter, value: str) -> List[str]:
    """Ensure additional paths exist.

    Args:
        ctx: The click context.
        param: The click parameter.
        value: The comma-separated list of additional paths.

    Returns:
        The list of validated additional paths.

    Raises:
        click.BadParameter: If a path in the list does not exist.
    """
    paths = value.split(",") if value else []
    for path in paths:
        if path and not os.path.exists(path):
            raise click.BadParameter(f"Path '{path}' does not exist.")
    return paths


def extract_file_content(
    file_path: str,
    output_file: click.File,
    base_dir: str,
    exclude_dirs: List[str],
    exclude_files: List[str],
) -> None:
    """Extract the content of a single file and append it to the output file.

    Args:
        file_path: Path to the file to be processed.
        output_file: File object for the output file.
        base_dir: The base directory for relative path calculation.
        exclude_dirs: List of directories to exclude from extraction.
        exclude_files: List of files to exclude from extraction.
    """
    if any(exclude_dir in file_path for exclude_dir in exclude_dirs):
        logging.debug(f"Skipping excluded directory: {file_path}")
        return

    if file_path in exclude_files:
        logging.debug(f"Skipping excluded file: {file_path}")
        return

    try:
        with open(file_path, "r", encoding="utf-8") as infile:
            code = infile.read()
            output_file.write(f"\n# File: {os.path.relpath(file_path, base_dir)}\n")
            output_file.write(code)
            output_file.write("\n\n")  # Ensure separation between files
        logging.info(f"Successfully processed: {file_path}")
    except Exception as e:
        logging.error(f"Error reading {file_path}: {e}")


@click.command()
@click.option(
    "--root-dir",
    default=".",
    callback=validate_directory,
    help="The root directory of the project. Defaults to the current directory.",
)
@click.option(
    "--output-file",
    default="out/project_code_combined.txt",
    callback=validate_file,
    help="The output text file where the code will be saved. Defaults to 'out/project_code_combined.txt'.",
)
@click.option(
    "--include-extensions",
    default=".py,.sh,.toml,.md,.yml,.sql,.jinja",
    callback=validate_extensions,
    help="Comma-separated list of file extensions to include in the extraction. Defaults to '.py,.sh,.toml,.md'.",
)
@click.option(
    "--additional-dirs",
    default="",
    callback=validate_additional_paths,
    help="Comma-separated list of additional directories to include. Defaults to an empty list.",
)
@click.option(
    "--additional-files",
    default="",
    callback=validate_additional_paths,
    help="Comma-separated list of additional individual files to include. Defaults to an empty list.",
)
@click.option(
    "--exclude-dirs",
    default="",
    help="Comma-separated list of directories to exclude from the extraction. Defaults to an empty list.",
)
@click.option(
    "--exclude-files",
    default="",
    help="Comma-separated list of individual files to exclude from the extraction. Defaults to an empty list.",
)
def extract_code(
    root_dir: str,
    output_file: str,
    include_extensions: str,
    additional_dirs: str,
    additional_files: str,
    exclude_dirs: Optional[str],
    exclude_files: Optional[str],
) -> None:
    """Extract code from a Dockerized Python Poetry project directory and save it into a single text file."""
    logging.info("Starting code extraction")

    exclude_dirs_list = exclude_dirs.split(",") if exclude_dirs else []
    exclude_files_list = exclude_files.split(",") if exclude_files else []

    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    with open(output_file, "w", encoding="utf-8") as outfile:
        # Process directories
        for dir in [root_dir] + additional_dirs:
            logging.info(f"Processing directory: {dir}")
            for subdir, dirs, files in os.walk(dir):
                for file in files:
                    if any(file.endswith(ext) for ext in include_extensions if ext):
                        file_path = os.path.join(subdir, file)
                        extract_file_content(
                            file_path, outfile, root_dir, exclude_dirs_list, exclude_files_list
                        )

        # Process additional files explicitly
        for file_path in additional_files:  # Directly use additional_files here
            extract_file_content(
                file_path,
                outfile,
                os.path.commonpath([root_dir] + additional_files),
                exclude_dirs_list,
                exclude_files_list,
            )

    logging.info("Code extraction completed.")


if __name__ == "__main__":
    extract_code()
