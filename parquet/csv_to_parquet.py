#!/usr/bin/env python3
"""Convert a CSV file to parquet"""

import pandas
import io
import sys

IN_FILE, OUT_FILE = sys.argv[1], sys.argv[2]

if not OUT_FILE:
    print("Output file argument required.")
    exit(1)

data = pandas.read_csv(IN_FILE)
data.to_parquet(OUT_FILE, index=False)
