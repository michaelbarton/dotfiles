#!/bin/bash

set -o xtrace

FILE=$(mktemp -d)/dayone.mkd

cat <<EOF > ${FILE}
# Daily Agenda

## SMART goals

- [ ]
- [ ]
- [ ]
EOF

vim ${FILE}
cat ${FILE} | dayone2 new --tags daily-agenda
