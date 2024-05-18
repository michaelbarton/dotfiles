#!/bin/bash -ue

DIR="$HOME/.local/lib/telkas"
WIKIFOLDER="${HOME}/Dropbox/wiki/zettel"
TODAY=$(date +%Y%m%d)

for file in "${WIKIFOLDER}"/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].md; do
    filename=$(basename "${file}")
    if [[ "${filename}" != "${TODAY}.md" ]]; then
        PYTHONPATH=${DIR} python3 ${DIR}/telkas/today.py --directory ${WIKIFOLDER} --input-file "${file}"
        exit_status=$?
        if [ $exit_status -ne 0 ]; then
            echo "Python script failed with exit status $exit_status for file: ${file}"
            exit $exit_status
        fi
        trash "${file}"
    fi
done
