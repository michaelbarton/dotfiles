#!/bin/bash

set -o xtrace

FILE=$(mktemp -d)/daily_agenda.mkd

cat <<EOF > ${FILE}
# Daily Agenda

## Leave by ___

## SMART goals

- [ ] Reconcile previous budgets, update future budgets
- [ ]
- [ ]
- [ ] Fill out task list for next day
EOF

vim ${FILE}
cat ${FILE} | dayone2 new --tags daily-agenda
