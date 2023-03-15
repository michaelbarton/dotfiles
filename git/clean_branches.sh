#!/bin/bash
#
# Remove any local branches that don't exist on the origin
#

set -o errexit
set -o nouset

# Check if Git is installed
if ! git --version >/dev/null 2>&1; then
  echo "Error: Git is not installed. Please install Git and try again."
  exit 1
fi

# Check if the current directory is a Git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: The current directory is not a Git repository. Please navigate to a Git repository and try again."
  exit 1
fi

# Fetch the latest changes from the remote repository and prune deleted branches
git fetch --prune

# Get a list of merged branches and filter out the branches that no longer exist on the origin
merged_branches=$(git branch --merged | grep -v "\*" | grep -v "^\s*master" | grep -v "^\s*main" | xargs -n 1 git branch -r --contains | sed 's/origin\///' | uniq)

# Iterate through each local branch and check if it exists in the list of merged branches
for branch in $(git for-each-ref --format='%(refname:short)' refs/heads); do
  if ! echo "$merged_branches" | grep -q "^$branch$"; then
    echo "Skipping branch '$branch' as it either doesn't exist on the origin or isn't merged."
  else
    echo "Deleting branch '$branch' as it is merged and doesn't exist on the origin."
    git branch -d "$branch" 2>/dev/null || echo "Error: Could not delete branch '$branch'."
  fi
done

