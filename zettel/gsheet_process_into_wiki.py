#!/usr/bin/env python3
"""Loads all rows from a google doc into markdown wiki entries."""

import os
import logging

import click
import rich.logging
import gspread
from oauth2client import service_account

# Set up rich logging
logging.basicConfig(
    level="NOTSET", format="%(message)s", datefmt="[%X]", handlers=[rich.logging.RichHandler()]
)

@click.command("Process google doc into wiki entries.")
@click.option("--google-doc-url", "-u", type=str, required=True)
@click.option("--credentials-file", "-f", type=click.Path(exists=True, file_okay=True, dir_okay=False), required=True)
@click.option("--destination-directory", "-d", type=click.Path(exists=True, dir_okay=True, file_okay=False), required=True)
def main(google_doc_url: str, credentials_file: str, destination_directory: str) -> None:
    """Process google doc into wiki file entries."""

    if not google_doc_url.startswith("https://docs.google.com/spreadsheets/d/"):
        logging.critical(f"URL is not a google doc: %s", google_doc_url)
        exit(1)

    credentials = service_account.ServiceAccountCredentials.from_json_keyfile_name(
        credentials_file, ["https://spreadsheets.google.com/feeds"]
    )

    # Use the service account credentials to authenticate with Google
    # Then fetch the spreadsheet
    worksheet = gspread.authorize(credentials).open_by_url(google_doc_url).get_worksheet(0)

    # Get the headers from the first row
    headers = worksheet.row_values(1)

    # Iterate through the rows and create a dictionary for each row using the headers as keys
    for row in worksheet.get_all_values()[1:]:
        row_dict = {}
        for i, header in enumerate(headers):
            row_dict[header] = row[i]

        # Do something with the row dictionary here
        print(row_dict)

    # Mark each row as "processed" by adding a new column to the worksheet and setting the value to "processed"
    worksheet.add_cols(1)
    worksheet.update_cell(1, len(headers) + 1, "processed")
    for i in range(2, worksheet.row_count + 1):
        worksheet.update_cell(i, len(headers) + 1, "processed")




if __name__ == "__main__":
    main()
