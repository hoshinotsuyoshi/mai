#!/bin/bash
set -euo pipefail

TASKS="${HOME}/.config/mi/tasks"
mkdir -p "${TASKS}"
PWD=$(pwd)
TARGET="${PWD}/examples/tasks/summarize_pr"
cd "${TASKS}"
ln -sf ${TARGET}
cd -

git diff HEAD~3 HEAD | \
  ./mi run summarize_pr/summarize_pr | \
  ./mi run summarize_pr/translate_to_ja | \
  jq -r .main
