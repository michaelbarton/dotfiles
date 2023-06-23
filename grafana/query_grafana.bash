#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

CONTAINER_NAME=${1:?"Usage: $0 <container_name> [<additional_filter>]"}
URL="http://localhost:3100/loki/api/v1/query_range"
START_TIME=$(date -u -v-24H +%s)
END_TIME=$(date -u +%s)
QUERY="{pipelineName=\"${CONTAINER_NAME}\"} | json | line_format \"{{.log}}\" | json | line_format \"{{.message}}\" |= \"level=\""

# Check if the second argument (additional_filter) is provided
if [ $# -gt 1 ]; then
  ADDITIONAL_FILTER="|=\"${2}\""
  QUERY="${QUERY}${ADDITIONAL_FILTER}"
fi

RESPONSE=$(curl --get "${URL}" \
  --data-urlencode "query=${QUERY}" \
  --data-urlencode "start=${START_TIME}" \
  --data-urlencode "end=${END_TIME}" \
  --data-urlencode "limit=1000")

if [ "$(echo "$RESPONSE" | jq '.status')" != "\"success\"" ]; then
  echo "Error: Query failed. Response was: $RESPONSE" >&2
  exit 1
fi

echo "$RESPONSE" | jq -r ".data.result | map(.stream) | flatten | map(.message) | .[]"
