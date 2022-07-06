#!/usr/bin/env bash
set -ex

declare -x XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
declare -x NVIM_PACK_DIR="$XDG_DATA_HOME/nvim/site/pack"

declare -x LSP_CONFIG_DIR="$NVIM_PACK_DIR/packer/start/nvim-lspconfig"
declare -x MASON_DIR="$PWD"

nvim -u NONE -E -R --headless \
  --cmd "set rtp+=${LSP_CONFIG_DIR},${MASON_DIR}" \
  +"luafile scripts/autogen_metadata.lua" +q
