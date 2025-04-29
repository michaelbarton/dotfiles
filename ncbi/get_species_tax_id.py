#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
# "requests",
# ]
# ///

import requests
from xml.etree import ElementTree as ET
import sys


def species_to_id(species):
    # URL encode the species name
    species_encoded = requests.utils.quote(species)

    # fetch taxon id from NCBI
    response = requests.get(
        f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=taxonomy&term={species_encoded}"
    )

    # Parse XML from response text
    root = ET.fromstring(response.text)

    # Find the Id element and get its text
    id_element = root.find("./IdList/Id")

    # If the id_element exists, return its text (i.e., the taxon ID), otherwise return an error message
    if id_element is not None:
        return id_element.text
    else:
        return "No taxon ID found for the provided species."


# Fetch the species name from the command line argument
species = sys.argv[1]

# Call the function and print the result
print(species_to_id(species))
