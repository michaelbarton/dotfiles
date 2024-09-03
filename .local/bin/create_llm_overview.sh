#!/bin/bash

#!/usr/bin/env bash
# Create a text file with the question to be asked to the chatbot
# Using the python files in the project to provide context

OUTFILE=$(mktemp -t llm_question_XXXXXX.txt)
TMPFILE=$(mktemp -t code_XXXXXX.txt)

~/.venv/bin/python3 ~/.dotfiles/poetry/poetry_to_markdown.py \
  --exclude-files='' \
  --include-extensions='.py,.sql,.toml,.md,.bash,.yml.,.vim,.nvim,.fish,.plist' \
  --exclude-dirs='' \
  --root-dir=. \
  --output-file=$TMPFILE

cat $TMPFILE | pbcopy

