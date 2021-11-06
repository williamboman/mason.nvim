local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local process = require "nvim-lsp-installer.process"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local platform = require "nvim-lsp-installer.platform"

return function(name, root_dir)
    local erlang_ls_file_ext = platform.is_win and ".cmd" or ""
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "erlang" },
        homepage = "https://erlang-ls.github.io/",
        installer = {
            std.ensure_executables {
                { "rebar3", "rebar3 was not found in path. Refer to http://rebar3.org/docs/." },
            },
            context.use_github_release "erlang-ls/erlang_ls",
            std.git_clone "https://github.com/erlang-ls/erlang_ls.git",
            function(_, callback, ctx)
                local c = process.chain {
                    cwd = ctx.install_dir,
                    stdio_sink = ctx.stdio_sink,
                }
                local rebar3 = platform.is_win and "rebar3.cmd" or "rebar3"
                c.run(rebar3, { "escriptize" })
                c.run(rebar3, { "as", "dap", "escriptize" })
                c.spawn(callback)
            end,
        },
        default_options = {
            cmd = { path.concat { root_dir, "_build", "default", "bin", ("erlang_ls%s"):format(erlang_ls_file_ext) } },
        },
    }
end
