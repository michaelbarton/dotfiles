#!/bin/bash
#
# View the contents of a parquet file, without having to decompress to a directory.
#
# Required `pip install visidata`

set -o errexit
set -o nounset

# Set the file path to the Parquet file
FILE_PATH=$1


# Check if the file exists
if [ ! -f "${FILE_PATH}" ]; then
  echo "Error: File not found at ${FILE_PATH}" >&2
  exit 1
fi

# Check if the file is compressed with Zstd
if file "$FILE_PATH" | grep -q "Zstandard compressed data"; then
  TMP=$(mktemp -d)/tmp.parquet
  zstdcat ${FILE_PATH} > ${TMP}
  FILE_PATH=${TMP}
fi

vd -f pandas "$FILE_PATH"

