local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "dprint",
    desc = [[A pluggable and configurable code formatting platform written in Rust.]],
    homepage = "https://dprint.dev/",
    languages = {},
    categories = { Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "dprint/dprint",
                asset_file = _.coalesce(
                    _.when(platform.is.mac_arm64, "dprint-aarch64-apple-darwin.zip"),
                    _.when(platform.is.mac_x64, "dprint-x86_64-apple-darwin.zip"),
                    _.when(platform.is.linux_arm64_gnu, "dprint-aarch64-unknown-linux-gnu.zip"),
                    _.when(platform.is.linux_x64_gnu, "dprint-x86_64-unknown-linux-gnu.zip"),
                    _.when(platform.is.win_x64, "dprint-x86_64-pc-windows-msvc.zip")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "dprint" })
        ctx:link_bin("dprint", platform.is.win and "dprint.exe" or "dprint")
    end,
}
