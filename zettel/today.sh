#!/bin/bash

set -o errexit
set -o nounset

DATE=$(gdate "+%Y%m%d")

# Set the source and destination file paths
SRC="${HOME}/Dropbox/wiki/zettel/202212031536_daily_template.md"
DEST="${HOME}/Dropbox/wiki/zettel/${DATE}.md"

# Copy the file to the destination if it does not already exist
if [ ! -s "${DEST}" ]; then
  cp "${SRC}" "${DEST}"
fi

# Open the file in vim
nvim "${DEST}"
