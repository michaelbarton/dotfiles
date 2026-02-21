#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "pandas",
#     "pyarrow"
# ]
# ///

"""Convert a CSV file to parquet"""

import pandas
import sys

if len(sys.argv) != 3:
    print("Usage: csv_to_parquet <input.csv> <output.parquet>")
    exit(1)

IN_FILE, OUT_FILE = sys.argv[1], sys.argv[2]

data = pandas.read_csv(IN_FILE)
data.to_parquet(OUT_FILE, index=False)
