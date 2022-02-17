#!/usr/bin/env python3
"""Convert a parquet file to CSV."""

import pandas
import io
import sys

IN_FILE, OUT_FILE = sys.argv[1], sys.argv[2]

if not OUT_FILE:
    print("Output file argument required.")
    exit(1)

data = pandas.read_parquet(IN_FILE)
data.to_csv(OUT_FILE, index=False)

