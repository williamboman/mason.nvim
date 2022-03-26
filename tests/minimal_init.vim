" Avoid neovim/neovim#11362
set display=lastline
set directory=""
set noswapfile

let $lsp_installer = getcwd()
let $test_helpers = getcwd() .. "/tests/helpers"
let $dependencies = getcwd() .. "/dependencies"

set rtp+=$lsp_installer,$test_helpers
set packpath=$dependencies

packloadall

lua require("luassertx")
lua require("test_helpers")

lua <<EOF
require("nvim-lsp-installer").settings {
    install_root_dir = os.getenv("INSTALL_ROOT_DIR"),
}
EOF

function! RunTests() abort
    lua <<EOF
    require("plenary.test_harness").test_directory(os.getenv("FILE") or "./tests", {
        minimal_init = vim.fn.getcwd() .. "/tests/minimal_init.vim",
    })
EOF
endfunction
