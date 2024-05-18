#!/bin/bash
#
# Create a pull request on GitHub using the CHANGELOG as a diff

set -o errexit
set -o nounset


# Is there a branch called master or main?
if git branch -a | grep 'remotes/origin/master'; then
  BASE=master
elif git branch -a | grep 'remotes/origin/main'; then
  BASE=main
else
  echo "No master or main branch found"
  exit 1
fi

FILE=$(mktemp -d)/pull_request.txt

cat > $FILE <<- EOM
\`\`\`diff
$(git diff --no-ext-diff ${BASE} -- CHANGELOG.md)
\`\`\`
EOM

git promote
gh pr create --body-file="${FILE}" "$@"
