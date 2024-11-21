#!/bin/bash

set -o nounset
set -o errexit

fd json $1 --print0 | xargs -0 -I {} just pachctl-update prod {}
