local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local process = require "nvim-lsp-installer.process"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local platform = require "nvim-lsp-installer.platform"

return function(name, root_dir)
    local rebar3 = platform.is_win and "rebar3.cmd" or "rebar3"

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "erlang" },
        homepage = "https://erlang-ls.github.io/",
        installer = {
            std.ensure_executables {
                { rebar3, ("%s was not found in path. Refer to http://rebar3.org/docs/."):format(rebar3) },
            },
            context.use_github_release "erlang-ls/erlang_ls",
            std.git_clone "https://github.com/erlang-ls/erlang_ls.git",
            function(_, callback, ctx)
                local c = process.chain {
                    cwd = ctx.install_dir,
                    stdio_sink = ctx.stdio_sink,
                }
                c.run(rebar3, { "escriptize" })
                c.run(rebar3, { "as", "dap", "escriptize" })
                c.spawn(callback)
            end,
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "_build", "default", "bin" } },
            },
        },
    }
end
