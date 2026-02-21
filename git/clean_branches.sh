#!/bin/bash
#
# Remove local branches that have been merged and no longer exist on the remote.
# Protects main, master, and the currently checked-out branch.
#
# Usage: clean_branches.sh [-f]
#   -f  Force delete unmerged branches that no longer exist on remote

set -o errexit
set -o nounset

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository."
  exit 1
fi

force_delete=false
if [[ "${1:-}" == "-f" ]]; then
  force_delete=true
fi

# Fetch and prune remote tracking branches
git fetch --prune

current_branch=$(git symbolic-ref --short HEAD)

# Delete local branches that have been merged into the current branch
git branch --merged | while read -r branch; do
  branch=$(echo "$branch" | tr -d '* ')
  # Skip protected branches
  if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "$current_branch" ]]; then
    continue
  fi
  echo "Deleting merged branch '$branch'"
  git branch -d "$branch" 2>/dev/null || echo "  Could not delete '$branch'"
done

# Optionally force-delete branches whose remote tracking branch is gone
if [ "$force_delete" = true ]; then
  git branch -vv | grep ': gone]' | while read -r line; do
    branch=$(echo "$line" | awk '{print $1}')
    if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "$current_branch" ]]; then
      continue
    fi
    echo "Force deleting gone branch '$branch'"
    git branch -D "$branch" 2>/dev/null || echo "  Could not delete '$branch'"
  done
fi
