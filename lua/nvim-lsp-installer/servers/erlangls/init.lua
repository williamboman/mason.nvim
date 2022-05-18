local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local process = require "nvim-lsp-installer.core.process"
local platform = require "nvim-lsp-installer.core.platform"
local std = require "nvim-lsp-installer.core.managers.std"
local git = require "nvim-lsp-installer.core.managers.git"
local github = require "nvim-lsp-installer.core.managers.github"
local Optional = require "nvim-lsp-installer.core.optional"

return function(name, root_dir)
    local rebar3 = platform.is_win and "rebar3.cmd" or "rebar3"

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "erlang" },
        homepage = "https://erlang-ls.github.io/",
        ---@param ctx InstallContext
        installer = function(ctx)
            std.ensure_executable(rebar3, { help_url = "http://rebar3.org/docs/" })

            local repo = "erlang-ls/erlang_ls"
            local source = github.tag { repo = repo }
            source.with_receipt()
            git.clone { ("https://github.com/%s.git"):format(repo), version = Optional.of(source.tag) }

            ctx.spawn[rebar3] { "escriptize" }
            ctx.spawn[rebar3] { "as", "dap", "escriptize" }
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "_build", "default", "bin" } },
            },
        },
    }
end
