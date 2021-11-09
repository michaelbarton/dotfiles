#!/usr/bin/env python3
"""
Take a pubmed ID and creates a markdown page with article metadata as the YAML 
front matter.
"""

from urllib import parse
import datetime
import os
import pathlib
import subprocess
import textwrap

import click
import funcy
import pydantic
import requests

EDITOR = os.environ.get('EDITOR','vim')


class PubmedRecord(pydantic.BaseModel):
    """Class to track the required fields in a pubmed entry."""
    first_author: str
    title: str
    journal: str
    date_published: datetime.date
    pubmed_id: int

    def key(self) -> str:
        """Generate a key using the author and year."""
        author = self.first_author.lower().split(" ")[0]
        return f"{author}_{self.date_published.year}"


def generate_url(pubmed_id: str) -> str:
    """Fetch the pubmed entry for the given ID."""
    return parse.urlunparse(
        (
            "https",
            "eutils.ncbi.nlm.nih.gov",
            "/entrez/eutils/esummary.fcgi",
            "",
            f"db=pubmed&id={pubmed_id}&retmode=json",
            "",
        )
    )

def parse_entry_date(date_field: str) -> datetime.datetime:
    """Function to handle variability in publication dates."""
    _f = funcy.rpartial(datetime.datetime.strptime, "%Y %b %d")
    field_length = len(date_field.strip().split(" "))

    if field_length == 3:
        return _f(date_field)

    if field_length == 2:
        return _f(date_field + " 01")

    if field_length == 1:
        return _f(date_field + " Jan 01")

def parse_pubmed_response(response, pubmed_id: str) -> PubmedRecord:
    """Parse the JSON reponse from the pubmed API into a PubmedRecord."""
    # Raise an error if could not fetch the URL.
    response.raise_for_status()

    if not response.json()["result"][pubmed_id]:
        raise RuntimeError(f"Could not find pubmed ID {pubmed_id} in response.")

    response_body = response.json()["result"][pubmed_id]

    return PubmedRecord(
        first_author=response_body["sortfirstauthor"],
        journal=response_body["source"],
        title=response_body["title"],
        pubmed_id=pubmed_id,
        date_published=parse_entry_date(response_body["pubdate"]),
    )


def create_article_file(record: PubmedRecord) -> None:
    """Create article record file with pubmed metadata."""
    file_name = datetime.datetime.today().strftime("%Y%m%d%H%M") + f"_{record.key()}.md"
    file_path = pathlib.Path.home() / "Dropbox/wiki/literature" / file_name
    file_path.write_text(
        textwrap.dedent(
            f"""
---
key: {record.key()}
title: "{record.title}"
read: False
year: {record.date_published.year}
date: {record.date_published}
pubmed: "https://pubmed.ncbi.nlm.nih.gov/{record.pubmed_id}/"
uuid: {record.pubmed_id}
---
            """.strip()
        )
    )
    return file_path


@click.command()
@click.argument("pubmed_id", type=str)
def run(pubmed_id: str):
    pubmed_url = generate_url(pubmed_id)
    pubmed_record = parse_pubmed_response(requests.get(pubmed_url), pubmed_id)
    file_record = create_article_file(pubmed_record)
    subprocess.call([EDITOR, str(file_record.absolute())])


if __name__ == "__main__":
    run()
