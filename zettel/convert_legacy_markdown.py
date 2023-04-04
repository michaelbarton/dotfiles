"""Script to convert the old legacy journal entries into the current format."""

import re
from datetime import datetime
import sys


def convert_date_string(date_string: str) -> str:
    """Convert the legacy date string into the new format date string."""
    normalised_date = re.sub(
        re.compile(r"\s+"), " ", date_string.strip("=").strip().replace(",", "")
    )
    fields = normalised_date.split()

    # Halfway through the journal I changed the format of the entries.
    fields[0] = fields[0][0:3]
    fields[1] = fields[1][0:3]
    if fields[2].isdigit():
        fields[1], fields[2] = fields[2], fields[1]

    # Create a truncated date string and then parse that.
    date_object = datetime.strptime(" ".join(fields[0:4]), "%a %d %b %Y")
    return date_object.strftime("%Y%m%d")


def parse_markdown(src_file: str, dst_file: str):
    with open(src_file, "r") as f:
        data = f.read()

    # Split the document into a list of entries, skip empty ones
    entries = [x for x in re.split(r"=+", data) if x]

    # Convert into a list of entries
    parsed_data = {
        convert_date_string(date): text
        for (date, text) in [(entries[i], entries[i + 1]) for i in range(0, len(entries), 2)]
    }

    # Then write out
    with open(dst_file, "w") as fh_out:
        for date, entry in parsed_data.items():
            fh_out.write(f"## [[{date}]]\n\n{entry}\n\n")

    return parsed_data


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) != 2:
        sys.stderr.write("Error, not enough arguments given.\n")
        exit(1)

    parse_markdown(*args)
