#!/bin/bash
set -euo pipefail

TASKS="${HOME}/.config/mai/tasks"
mkdir -p "${TASKS}"
PWD=$(pwd)
TARGET="${PWD}/examples/tasks/update_readme"
cd "${TASKS}"
ln -sf ${TARGET}
cd -

./mai run update_readme/update_readme --no-stdin | \
  jq -r .main
