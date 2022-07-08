#!/usr/bin/env bash

set -exuo pipefail

declare -x DEPENDENCIES="${PWD}/dependencies"
declare -x MASON_DIR="$PWD"
declare -x MASON_SCRIPT_DIR="${PWD}/scripts"

nvim -u NONE -E -R --headless \
  --cmd "set rtp+=${MASON_SCRIPT_DIR},${MASON_DIR},${DEPENDENCIES}" \
  +"luafile $1" +q
