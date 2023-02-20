local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "buildifier",
    desc = [[buildifier is a tool for formatting and linting bazel BUILD, WORKSPACE, and .bzl files.]],
    homepage = "https://github.com/bazelbuild/buildtools",
    languages = { Pkg.Lang.Bazel },
    categories = { Pkg.Cat.Linter, Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "bazelbuild/buildtools",
                out_file = platform.is.win and "buildifier.exe" or "buildifier",
                asset_file = coalesce(
                    when(platform.is.mac_x64, "buildifier-darwin-amd64"),
                    when(platform.is.mac_arm64, "buildifier-darwin-arm64"),
                    when(platform.is.linux_x64, "buildifier-linux-amd64"),
                    when(platform.is.linux_arm64, "buildifier-linux-arm64"),
                    when(platform.is.win_x64, "buildifier-windows-amd64.exe")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "buildifier" })
        ctx:link_bin("buildifier", platform.is.win and "buildifier.exe" or "buildifier")
    end,
}
