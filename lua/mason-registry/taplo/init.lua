local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "taplo",
    desc = [[A versatile, feature-rich TOML toolkit.]],
    homepage = "https://taplo.tamasfe.dev/",
    languages = { Pkg.Lang.TOML },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        platform.when {
            unix = function()
                github
                    .gunzip_release_file({
                        repo = "tamasfe/taplo",
                        asset_file = coalesce(
                            when(platform.is.mac_arm64, "taplo-full-darwin-aarch64.gz"),
                            when(platform.is.mac_x64, "taplo-full-darwin-x86_64.gz"),
                            when(platform.is.linux_x64, "taplo-full-linux-x86_64.gz"),
                            when(platform.is.linux_x86, "taplo-full-linux-x86.gz"),
                            when(platform.is.linux_arm64, "taplo-full-linux-aarch64.gz")
                        ),
                        out_file = "taplo",
                    })
                    .with_receipt()
                std.chmod("+x", { "taplo" })
                ctx:link_bin("taplo", "taplo")
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = "tamasfe/taplo",
                        asset_file = coalesce(
                            when(platform.is.win_x64, "taplo-full-windows-x86_64.zip"),
                            when(platform.is.win_x86, "taplo-full-windows-x86.zip")
                        ),
                        out_file = "taplo.zip",
                    })
                    .with_receipt()
                ctx:link_bin("taplo", "taplo.exe")
            end,
        }
    end,
}
