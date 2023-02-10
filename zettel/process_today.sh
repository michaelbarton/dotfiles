#!/bin/bash -ue

DIR="$HOME/.local/lib/telkas"
PYTHONPATH=${DIR} python3 ${DIR}/telkas/today.py --directory ${HOME}/Dropbox/wiki/zettel/ --input-file $1
trash $1
