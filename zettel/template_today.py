"""Use the daily template to create a file for today."""

import datetime
import os
import random
import re
from typing import List, Dict, Any

import click
import jinja2


def should_be_reviewed(src_dir: str, file: str) -> bool:
    """Check if the file is a page that should be reviewed page.

    Notes:
      - Excludes previous daily files.
      - Excludes files containing the tag `#noreview`

    """
    src_file = os.path.join(src_dir, file)
    if not os.path.isfile(src_file):
        return False
    # Use a regular expression to filter out files that are just a date string in
    # the format %Y%m%d. These are daily todo pages.
    if re.match(r"[0-9]{8}.md$", file):
        return False
    # Skip the file if it contains the `#noreview` tag.
    with open(src_file, "r") as f:
        if "#noreview" in f.read():
            return False
    return True


def pick_random_files(directory: str, n: int = 3) -> List[str]:
    """Randomly pick N files for review from the wiki."""

    # Get a list of all files in the directory
    files = os.listdir(directory)

    # Remove the file extension for the wiki format
    files = [f.replace(".md", "") for f in files if should_be_reviewed(directory, f)]
    # Select three random files from the filtered list
    random_files = random.sample(files, n)
    return random_files


def create_template_metadata(src_dir: str, today: str) -> Dict[str, Any]:
    """Create a metadata dictionary used by the file template.

    Notes:
      Additional metadata should be added here.

    """
    return {"date": today, "review_files": pick_random_files(src_dir)}


@click.command("Create a new file for today using the given jinja template.")
@click.option(
    "--template-file",
    "-t",
    type=click.Path(exists=True, file_okay=True, dir_okay=False),
    required=True,
)
@click.option(
    "--source-directory",
    "-d",
    type=click.Path(exists=True, file_okay=False, dir_okay=True),
    required=True,
)
@click.option(
    "--output-directory",
    "-o",
    type=click.Path(exists=False, file_okay=False, dir_okay=True),
    required=True,
)
def main(template_file: str, source_directory: str, output_directory: str) -> None:
    """Create a new file for today using the given jinja template."""

    today = f"{datetime.date.today():%Y%m%d}"
    output_file = os.path.join(output_directory, f"{today}.md")

    # Create jinja template
    with open(template_file, "r") as template_file:
        template = jinja2.Template(template_file.read(), trim_blocks=True, lstrip_blocks=True)

    # Create today's daily file
    with open(output_file, "w") as fh_out:
        fh_out.write(template.render(**create_template_metadata(source_directory, today)))


if __name__ == "__main__":
    main()
