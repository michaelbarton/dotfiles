#!/bin/bash

set -o errexit
set -o nounset

IN_FILE=$1

# See: https://stackoverflow.com/a/965072/91144
FILENAME=$(basename -- "$IN_FILE")
FILENAME_NOEXT="${FILENAME%.*}"

pandoc -o ${FILENAME_NOEXT}.docx -f markdown -t docx $IN_FILE
