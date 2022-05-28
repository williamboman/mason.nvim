local server = require "nvim-lsp-installer.server"
local a = require "nvim-lsp-installer.core.async"
local _ = require "nvim-lsp-installer.core.functional"
local installer = require "nvim-lsp-installer.core.installer"
local path = require "nvim-lsp-installer.core.path"
local functional = require "nvim-lsp-installer.core.functional"
local platform = require "nvim-lsp-installer.core.platform"
local process = require "nvim-lsp-installer.core.process"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    local repo = "valentjn/ltex-ls"
    ---@async
    local function download_platform_dependent()
        local ctx = installer.context()
        local source = platform.when {
            unix = function()
                return github.untargz_release_file {
                    repo = repo,
                    asset_file = function(version)
                        local target = coalesce(
                            when(platform.is_mac, "ltex-ls-%s-mac-x64.tar.gz"),
                            when(platform.is_linux, "ltex-ls-%s-linux-x64.tar.gz"),
                            when(platform.is_win, "ltex-ls-%s-windows-x64.zip")
                        )
                        return target:format(version)
                    end,
                }
            end,
            win = function()
                return github.unzip_release_file {
                    repo = repo,
                    asset_file = function(version)
                        return ("ltex-ls-%s-windows-x64.zip"):format(version)
                    end,
                }
            end,
        }
        source.with_receipt()
        ctx.fs:rename(("ltex-ls-%s"):format(source.release), "ltex-ls")
    end

    local function download_platform_independent()
        local ctx = installer.context()
        local source = github.untargz_release_file {
            repo = repo,
            asset_file = _.format "ltex-ls-%s.tar.gz",
        }
        source.with_receipt()
        ctx.fs:rename(("ltex-ls-%s"):format(source.release), "ltex-ls")
    end

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://valentjn.github.io/vscode-ltex",
        languages = { "latex" },
        ---@async
        installer = function()
            if vim.in_fast_event() then
                a.scheduler()
            end
            if vim.fn.executable "java" == 1 then
                download_platform_independent()
            else
                download_platform_dependent()
            end
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "ltex-ls", "bin" } },
            },
        },
    }
end
