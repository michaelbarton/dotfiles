#!/usr/bin/env python3

from datetime import datetime
from email import policy
import email
import os
import pathlib
import re
import subprocess
import textwrap

import click
import bs4

EDITOR = os.environ.get("EDITOR", "vim")


@click.command()
@click.argument("filepath", type=click.Path(exists=True))
@click.option("--skip-edit", "-e", default=False, is_flag=True)
def run(filepath: str, skip_edit: bool):
    # Read email from file.
    contents = pathlib.Path(filepath).read_text()
    msg = email.message_from_string(contents, policy=policy.default)

    # Parse dateline
    # Should throw an error if not correctly formatted
    date_subject = datetime.strptime(msg.get("Subject"), "%Y%m%d")
    date_str = date_subject.strftime("%Y%m%d")

    # Convert html contents to plain text
    email_body = str(msg.get_content()).replace("=\n", "")
    soup = bs4.BeautifulSoup(email_body, features="html.parser")

    # Strip out weird characters and footer.
    body = re.sub(
        "--Sent from.+", "", soup.get_text().replace("=E2=80=A2 =E2=80=A2 =E2=80=A2", "\n")
    )

    # Wrap text to 80 chars
    body = f"# [[{date_str}]]\n" + body.replace("#", "\n\n#")

    # Write to file
    dst_file = pathlib.Path.home() / f"Dropbox/wiki/unprocessed/{date_str}_daily_log.md"
    dst_file.write_text(body)

    if skip_edit:
        return

    subprocess.call([EDITOR, str(dst_file.absolute())])


if __name__ == "__main__":
    run()
