local Pkg = require "mason-core.package"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "ada-language-server",
    desc = [[Ada/SPARK language server]],
    homepage = "https://github.com/AdaCore/ada_language_server",
    languages = { Pkg.Lang.Ada },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "AdaCore/ada_language_server",
                asset_file = function(release)
                    local target = coalesce(
                        when(platform.is.mac, "als-%s-macOS_amd64.zip"),
                        when(platform.is.linux_x64, "als-%s-Linux_amd64.zip"),
                        when(platform.is.win_x64, "als-%s-Windows_amd64.zip")
                    )
                    return target and target:format(release)
                end,
            })
            .with_receipt()

        local binary = coalesce(
            when(platform.is.mac, path.concat { "darwin", "ada_language_server" }),
            when(platform.is.linux_x64, path.concat { "linux", "ada_language_server" }),
            when(platform.is.win_x64, path.concat { "win32", "ada_language_server.exe" })
        )
        ctx:link_bin("ada_language_server", binary)
    end,
}
