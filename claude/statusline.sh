#!/usr/bin/env bash
# Claude Code status line: "[model] branch · N% context".
# Claude Code passes session JSON on stdin; this reads model.display_name,
# workspace.current_dir and context_window.used_percentage (null early in a
# session). Any parse failure prints a plain fallback so the bar never goes
# blank or shows an error.

input=$(cat 2>/dev/null) || input=""

model=$(printf '%s' "$input" | jq -r '.model.display_name // empty' 2>/dev/null) || model=""
dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null) || dir=""
pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // 0 | floor' 2>/dev/null) || pct=""

if [ -z "$model" ] || [ -z "$pct" ]; then
  echo "claude"
  exit 0
fi

branch=""
if [ -n "$dir" ] && [ -d "$dir" ]; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null) || branch=""
fi

if [ -n "$branch" ]; then
  printf '[%s] %s · %s%% context\n' "$model" "$branch" "$pct"
else
  printf '[%s] %s%% context\n' "$model" "$pct"
fi
