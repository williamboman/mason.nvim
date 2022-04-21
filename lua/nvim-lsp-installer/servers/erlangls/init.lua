local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"
local std = require "nvim-lsp-installer.core.managers.std"
local github_client = require "nvim-lsp-installer.core.managers.github.client"
local git = require "nvim-lsp-installer.core.managers.git"
local Optional = require "nvim-lsp-installer.core.optional"

return function(name, root_dir)
    local rebar3 = platform.is_win and "rebar3.cmd" or "rebar3"

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "erlang" },
        homepage = "https://erlang-ls.github.io/",
        async = true,
        ---@param ctx InstallContext
        installer = function(ctx)
            std.ensure_executable(rebar3, { help_url = "http://rebar3.org/docs/" })

            local repo = "erlang-ls/erlang_ls"
            ctx.requested_version = ctx.requested_version:or_(function()
                return Optional.of(github_client.fetch_latest_tag(repo)
                    :map(function(tag)
                        return tag.name
                    end)
                    :get_or_throw "Failed to fetch latest tag.")
            end)
            git.clone({ ("https://github.com/%s.git"):format(repo) }).with_receipt()

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
