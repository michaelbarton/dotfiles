#!/bin/bash -ue

DIR="$HOME/cache/telkas"
PYTHONPATH=${DIR} ${DIR}/bin/telkas --directory ${HOME}/Dropbox/wiki/zettel/ --input-file $1
