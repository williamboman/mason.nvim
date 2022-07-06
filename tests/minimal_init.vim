" Avoid neovim/neovim#11362
set display=lastline
set directory=""
set noswapfile

let $mason = getcwd()
let $test_helpers = getcwd() .. "/tests/helpers"
let $dependencies = getcwd() .. "/dependencies"

set rtp+=$mason,$test_helpers
set packpath=$dependencies

packloadall

lua require("luassertx")
lua require("test_helpers")

lua <<EOF
local pkg_index = require "mason._generated.package_index"
pkg_index["dummy"] = "dummy_package"

require("mason").setup {
    install_root_dir = os.getenv("INSTALL_ROOT_DIR"),
}
EOF

function! RunTests() abort
    lua <<EOF
    require("plenary.test_harness").test_directory(os.getenv("FILE") or "./tests", {
        minimal_init = vim.fn.getcwd() .. "/tests/minimal_init.vim",
        sequential = true,
    })
EOF
endfunction
