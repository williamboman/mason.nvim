local Optional = require "mason-core.optional"
local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local github_client = require "mason-core.managers.github.client"
local platform = require "mason-core.platform"
local std = require "mason-core.managers.std"

return Pkg.new {
    name = "vls",
    desc = [[V language server]],
    homepage = "https://github.com/vlang/vls",
    languages = { Pkg.Lang.V },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "vlang/vls"

        github
            .download_release_file({
                version = Optional.of "latest",
                repo = repo,
                out_file = platform.is.win and "vls.exe" or "vls",
                asset_file = _.coalesce(
                    _.when(platform.is.linux_x64, "vls_linux_x64"),
                    _.when(platform.is.mac, "vls_macos_x64"),
                    _.when(platform.is.win_x64, "vls_windows_x64.exe")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "vls" })
        ctx:link_bin("vls", platform.is.win and "vls.exe" or "vls")
    end,
}
