#!/bin/bash

set -o xtrace

FILE=$(mktemp -d)/dayone.mkd

cat <<EOF > ${FILE}
#
EOF

vim ${FILE}
cat ${FILE} | dayone2 new
