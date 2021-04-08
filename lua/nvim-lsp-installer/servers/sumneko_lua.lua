local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('lua')

local install_cmd = [=[
rm -rf lua-language-server;
git clone https://github.com/sumneko/lua-language-server;
cd lua-language-server/;
git submodule update --init --recursive;
cd 3rd/luamake;
if [[ $(uname) == Darwin ]]; then
    ninja -f ninja/macos.ninja;
elif [[ $(uname) == Linux ]]; then
    ninja -f ninja/linux.ninja;
else
    >&2 echo "$(uname) not supported.";
    exit 1;
fi
cd ../../;
./3rd/luamake/luamake rebuild;
]=]

local uname_alias = {
    Darwin = 'macOS',
}
local uname = vim.fn.system('uname'):gsub("%s+", "")
local bin_dir = uname_alias[uname] or uname

return server.Server:new {
    name = "sumneko_lua",
    root_dir = root_dir,
    install_cmd = install_cmd,
    pre_install_check = function()
        if vim.fn.executable('ninja') ~= 1 then
            error("ninja not installed (see https://github.com/ninja-build/ninja/wiki/Pre-built-Ninja-packages)")
        end
    end,
    default_options = {
        cmd = { root_dir .. "/lua-language-server/bin/" .. bin_dir .. "/lua-language-server" , "-E", root_dir .. "/lua-language-server/main.lua"},
        settings = {
            Lua = {
                diagnostics = {
                    -- Get the language server to recognize the `vim` global
                    globals = {'vim'}
                },
                workspace = {
                    -- Make the server aware of Neovim runtime files
                    library = {
                        [vim.fn.expand('$VIMRUNTIME/lua')] = true,
                        [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
                    },
                    maxPreload = 10000
                }
            }
        },
    }
}
