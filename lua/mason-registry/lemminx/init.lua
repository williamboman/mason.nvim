local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "lemminx",
    desc = [[XML Language Server]],
    homepage = "https://github.com/eclipse/lemminx",
    languages = { Pkg.Lang.XML },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local source = github.unzip_release_file {
            repo = "redhat-developer/vscode-xml",
            asset_file = coalesce(
                when(platform.is.mac, "lemminx-osx-x86_64.zip"),
                when(platform.is.linux_x64, "lemminx-linux.zip"),
                when(platform.is.win, "lemminx-win32.zip")
            ),
        }
        source.with_receipt()
        local unzipped_binary = _.gsub("%.zip$", "", source.asset_file)
        ctx.fs:rename(
            platform.is.win and ("%s.exe"):format(unzipped_binary) or unzipped_binary,
            platform.is.win and "lemminx.exe" or "lemminx"
        )
        ctx:link_bin("lemminx", platform.is.win and "lemminx.exe" or "lemminx")
    end,
}
