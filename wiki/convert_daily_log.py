#!/usr/bin/env python3

from datetime import datetime
from email import policy
import email
import os
import pathlib
import subprocess

import click
import bs4

EDITOR = os.environ.get('EDITOR','vim')


@click.command()
@click.argument("filepath", type=click.Path(exists=True))
def run(filepath: str):

    # Read email from file.
    contents = pathlib.Path(filepath).read_text()
    msg = email.message_from_string(contents, policy=policy.default)

    # Parse dateline
    # Should throw an error if not correctly formatted
    date_subject = datetime.strptime(msg.get("Subject"), "%Y%m%d")

    # Convert html contents to plain text
    email_body = str(msg.get_body()).replace("=\n", "")
    soup = bs4.BeautifulSoup(email_body, features="html.parser")
    body = soup.get_text().replace("=E2=80=A2 =E2=80=A2 =E2=80=A2", "\n")

    # Write to file
    dst_file = (
        pathlib.Path.home()
        / f"Dropbox/wiki/unprocessed/{date_subject.strftime('%Y%m%d')}_daily_log.md"
    )
    dst_file.write_text(body)
    subprocess.call([EDITOR, str(dst_file.absolute())])


run()
