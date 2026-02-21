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

IN_FILE, OUT_FILE = sys.argv[1], sys.argv[2]

if not OUT_FILE:
    print("Output file argument required.")
    exit(1)

data = pandas.read_csv(IN_FILE)
data.to_parquet(OUT_FILE, index=False)
