#!/usr/bin/env bash

set -exuo pipefail

declare -x DEPENDENCIES="${PWD}/dependencies"
declare -x MASON_DIR="$PWD"
declare -x MASON_SCRIPT_DIR="${PWD}/scripts"

nvim -u NONE -E -R --headless \
  --cmd "set rtp^=${MASON_SCRIPT_DIR},${MASON_DIR}" \
  --cmd "set packpath^=${DEPENDENCIES}" \
  --cmd "packloadall" \
  --cmd "luafile $1" \
  --cmd "q"
