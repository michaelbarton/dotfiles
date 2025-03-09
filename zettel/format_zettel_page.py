#!/usr/bin/env python3


"""
A tool for sorting date entries in markdown reflection files.

This script takes a markdown file containing dated entries in the format '## [[YYYYMMDD]]'
and sorts them in descending order while preserving the preamble content.
"""

import os
import re
from datetime import datetime
from pathlib import Path
from typing import Optional

import click
from click.testing import CliRunner


def sort_markdown_entries(content: str) -> str:
    """
    Sort markdown entries by date in descending order while preserving the preamble.

    The function identifies date entries in the format '## [[YYYYMMDD]]' and sorts them
    from newest to oldest. Content before the first date entry (preamble) is preserved
    in its original position.

    Args:
        content: The full content of the markdown file as a string.

    Returns:
        A string containing the sorted markdown content with preserved preamble.
    """
    # Regular expression patterns
    date_header_pattern = re.compile(r"## \[\[(\d{8})\]\]")
    entry_pattern = re.compile(r"(## \[\[\d{8}\]\].*?)(?=(## \[\[\d{8}\]\])|\Z)", re.DOTALL)

    # Split content into preamble and entries
    entries = entry_pattern.findall(content)
    if not entries:
        return content  # No entries to sort

    # Find the position of the first entry to identify the preamble
    first_entry_match = entry_pattern.search(content)
    preamble = content[: first_entry_match.start()] if first_entry_match else ""

    # Extract entries and their dates
    entry_date_pairs = []
    for entry in entries:
        date_match = date_header_pattern.match(entry[0])
        if date_match:
            date = datetime.strptime(date_match.group(1), "%Y%m%d")
            entry_date_pairs.append((date, entry[0]))
        else:
            raise ValueError(f"No valid date found in entry: {entry[0]}")

    # Sort entries by date in descending order
    sorted_entries = [
        entry for _, entry in sorted(entry_date_pairs, key=lambda x: x[0], reverse=True)
    ]

    # Combine preamble with sorted entries
    return preamble + "".join(sorted_entries)


def write_markdown_file(content: str, file_path: str) -> None:
    """
    Write content to a markdown file.

    Args:
        content: The content to write to the file.
        file_path: Path where the file should be written.
    """
    with open(file_path, "w", encoding="utf-8") as file:
        file.write(content)


@click.command()
@click.argument("input_file", type=click.Path(exists=True, readable=True))
@click.argument("output_file", type=click.Path(writable=True), required=False)
@click.option(
    "--in-place",
    "-i",
    is_flag=True,
    help="Update the input file in place instead of writing to a new file",
)
@click.option(
    "--dry-run",
    "-d",
    is_flag=True,
    help="Print the sorted content without writing to file",
)
@click.option(
    "--backup/--no-backup",
    default=True,
    help="Create a backup before in-place update (default: enabled)",
)
def main(
    input_file: str,
    output_file: Optional[str],
    in_place: bool,
    dry_run: bool,
    backup: bool,
) -> None:
    """
    Sort date entries in a markdown file while preserving the preamble.

    INPUT_FILE: Path to the input markdown file
    OUTPUT_FILE: Path where the sorted markdown should be written (optional if --in-place is used)

    Examples:
        # Write to new file:
        python script.py input.md output.md

        # Update in place:
        python script.py -i input.md

        # Preview changes:
        python script.py input.md --dry-run
    """
    if in_place and output_file:
        raise click.UsageError("Cannot specify output file when using --in-place option")

    if not in_place and not output_file and not dry_run:
        raise click.UsageError("Must specify output file or use --in-place option")

    with open(input_file, "r", encoding="utf-8") as file:
        content = file.read()

    sorted_content = sort_markdown_entries(content)

    if dry_run:
        click.echo(sorted_content)
        return

    if in_place:
        input_path = Path(input_file)
        if backup:
            backup_path = input_path.with_suffix(input_path.suffix + ".bak")
            click.echo(f"Creating backup at {backup_path}")
            write_markdown_file(content, str(backup_path))

        write_markdown_file(sorted_content, input_file)
        click.echo(f"Successfully updated {input_file} in place")
    else:
        write_markdown_file(sorted_content, output_file)
        click.echo(f"Successfully sorted entries from {input_file} to {output_file}")


if __name__ == "__main__":
    main()

# Tests


def test_sort_markdown_entries() -> None:
    """Test sorting multiple entries in correct order."""
    input_content = """# Daily Reflection

#noreview

Related:
- [[./202208222131_who_do_I_want_to_be|Who do I want to be?]]
- [[202202131418_gratitude_journalling|Gratitude Journalling]]

## [[20231031]]
Today was productive.

## [[20231115]]
Had a great meeting.

## [[20231001]]
Feeling tired today.
"""

    expected_output = """# Daily Reflection

#noreview

Related:
- [[./202208222131_who_do_I_want_to_be|Who do I want to be?]]
- [[202202131418_gratitude_journalling|Gratitude Journalling]]

## [[20231115]]
Had a great meeting.

## [[20231031]]
Today was productive.

## [[20231001]]
Feeling tired today.
"""

    assert sort_markdown_entries(input_content) == expected_output


def test_cli_in_place_update() -> None:
    """Test in-place update functionality."""
    runner = CliRunner()
    with runner.isolated_filesystem():
        input_content = """# Test
## [[20231031]]
Entry 1
## [[20231115]]
Entry 2"""

        with open("input.md", "w") as f:
            f.write(input_content)

        result = runner.invoke(main, ["input.md", "--in-place"])
        assert result.exit_code == 0
        assert "Successfully updated" in result.output

        with open("input.md", "r") as f:
            updated_content = f.read()
            assert "## [[20231115]]" in updated_content
            assert updated_content.index("## [[20231115]]") < updated_content.index(
                "## [[20231031]]"
            )


def test_cli_in_place_with_backup() -> None:
    """Test in-place update with backup creation."""
    runner = CliRunner()
    with runner.isolated_filesystem():
        input_content = """# Test
## [[20231031]]
Entry 1
## [[20231115]]
Entry 2"""

        with open("input.md", "w") as f:
            f.write(input_content)

        result = runner.invoke(main, ["input.md", "--in-place"])
        assert result.exit_code == 0
        assert os.path.exists("input.md.bak")

        with open("input.md.bak", "r") as f:
            backup_content = f.read()
            assert backup_content == input_content


def test_cli_in_place_no_backup() -> None:
    """Test in-place update without backup."""
    runner = CliRunner()
    with runner.isolated_filesystem():
        with open("input.md", "w") as f:
            f.write(
                """# Test
## [[20231031]]
Entry 1"""
            )

        result = runner.invoke(main, ["input.md", "--in-place", "--no-backup"])
        assert result.exit_code == 0
        assert not os.path.exists("input.md.bak")
