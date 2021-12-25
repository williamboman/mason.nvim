" Avoid neovim/neovim#11362
set display=lastline
set directory=""
set noswapfile

let $lsp_installer = getcwd()
let $luassertx_rtp = getcwd() .. "/tests/luassertx"
let $dependencies = getcwd() .. "/dependencies"

set rtp+=$lsp_installer,$luassertx_rtp
set packpath=$dependencies

packloadall

lua <<EOF
local server = require("nvim-lsp-installer.server")
function ServerGenerator(opts)
    return server.Server:new(vim.tbl_deep_extend("force", {
        name = "dummy",
        languages = { "dummylang" },
        root_dir = server.get_server_root_path("dummy"),
        homepage = "https://dummylang.org",
        installer = function(_, callback, ctx)
            ctx.stdio_sink.stdout "Installing dummy!\n"
            callback(true)
        end
    }, opts))
end

function FailingServerGenerator(opts)
    return ServerGenerator(vim.tbl_deep_extend("force", {
        installer = function(_, callback, ctx)
            ctx.stdio_sink.stdout "Installing failing dummy!\n"
            callback(false)
        end
    }, opts))
end
EOF

" Luassert extensions
lua require("luassertx")

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
