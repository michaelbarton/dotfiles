#!/bin/bash

set -o errexit
set -o nounset

DATE=$(gdate "+%Y%m%d")

# Set the source and destination file paths
WIKI="${HOME}/Dropbox/wiki/zettel"
SRC="${WIKI}/202212031536_daily_template.md"
DST="${WIKI}/${DATE}.md"

# Copy the file to the destination if it does not already exist
if [ ! -s "${DST}" ]; then
  python3 ~/.dotfiles/zettel/template_today.py \
  	--template-file=${SRC} \
	--source-directory=${WIKI} \
	--output-directory=${WIKI}
fi

# Open the file in vim
nvim "${DST}"
