#!/opt/homebrew/bin/python3

import os
import click
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

def validate_directory(ctx, param, value):
    """Validate that the directory exists."""
    if value and not os.path.isdir(value):
        raise click.BadParameter(f"Directory '{value}' does not exist.")
    return value

def validate_file(ctx, param, value):
    """Validate that the file path is valid or the file doesn't exist yet."""
    if value and os.path.isdir(value):
        raise click.BadParameter("Please provide a valid file path, not a directory.")
    return value

def validate_extensions(ctx, param, value):
    """Ensure extensions are provided correctly."""
    if not value:
        raise click.BadParameter("You must specify at least one file extension.")
    extensions = value.split(",")
    for ext in extensions:
        if ext and not ext.startswith("."):
            raise click.BadParameter("File extensions must start with a '.' character.")
    return extensions

def validate_additional_paths(ctx, param, value):
    """Ensure additional paths exist."""
    paths = value.split(",") if value else []
    for path in paths:
        if path and not os.path.exists(path):
            raise click.BadParameter(f"Path '{path}' does not exist.")
    return paths

def extract_file_content(file_path, output_file, base_dir):
    """
    Extracts the content of a single file and appends it to the output file.

    :param file_path: Path to the file to be processed.
    :param output_file: File object for the output file.
    :param base_dir: The base directory for relative path calculation.
    """
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
    help="The root directory of the project.",
)
@click.option(
    "--output-file",
    default="out/project_code_combined.txt",
    callback=validate_file,
    help="The output text file where the code will be saved.",
)
@click.option(
    "--include-extensions",
    default=".py,.sh,.toml,.md",
    callback=validate_extensions,
    help="Comma-separated list of file extensions to include in the extraction.",
)
@click.option(
    "--additional-dirs",
    default="",
    callback=validate_additional_paths,
    help="Comma-separated list of additional directories to include.",
)
@click.option(
    "--additional-files",
    default="",
    callback=validate_additional_paths,
    help="Comma-separated list of additional individual files to include.",
)
def extract_code(root_dir, output_file, include_extensions, additional_dirs, additional_files):
    """
    Extract code from a Dockerized Python Poetry project directory and save it into a single text file.
    """
    logging.info("Starting code extraction")

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
                        extract_file_content(file_path, outfile, root_dir)

        # Process additional files explicitly
        for file_path in additional_files:  # Directly use additional_files here
            extract_file_content(file_path, outfile, os.path.commonpath([root_dir] + additional_files))

    logging.info("Code extraction completed.")

if __name__ == "__main__":
    extract_code()

