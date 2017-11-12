#!/bin/bash

set -o xtrace

FILE=$(mktemp -d)/dayone.mkd

cat <<EOF > ${FILE}
# Daily Agenda

## Stretch Goal

## SMART goals

### Work

- [ ]
- [ ]
- [ ]

### Personal

- [ ]
- [ ]
- [ ]

EOF

vim ${FILE}
cat ${FILE} | dayone2 new --tags daily-agenda
