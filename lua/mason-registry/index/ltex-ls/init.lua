local Pkg = require "mason-core.package"
local a = require "mason-core.async"
local installer = require "mason-core.installer"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

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
                        when(platform.is.mac, "ltex-ls-%s-mac-x64.tar.gz"),
                        when(platform.is.linux_x64, "ltex-ls-%s-linux-x64.tar.gz")
                    )
                    return target and target:format(version)
                end,
            }
        end,
        win = function()
            return github.unzip_release_file {
                repo = repo,
                asset_file = function(version)
                    local target = coalesce(when(platform.is.win_x64, "ltex-ls-%s-windows-x64.zip"))
                    return target and target:format(version)
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

return Pkg.new {
    name = "ltex-ls",
    desc = _.dedent [[
        LTeX Language Server: LSP language server for LanguageTool 🔍✔️ with support for LaTeX 🎓, Markdown 📝, and
        others.
    ]],
    homepage = "https://valentjn.github.io/ltex/",
    languages = { Pkg.Lang.Text, Pkg.Lang.Markdown, Pkg.Lang.LaTeX },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        if vim.in_fast_event() then
            a.scheduler()
        end
        if vim.fn.executable "java" == 1 then
            download_platform_independent()
        else
            download_platform_dependent()
        end
        ctx:link_bin("ltex-ls", path.concat { "ltex-ls", "bin", platform.is.win and "ltex-ls.bat" or "ltex-ls" })
        ctx:link_bin("ltex-cli", path.concat { "ltex-ls", "bin", platform.is.win and "ltex-cli.bat" or "ltex-cli" })
    end,
}
