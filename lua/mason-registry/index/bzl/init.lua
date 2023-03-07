local Pkg = require "mason-core.package"
local std = require "mason-core.managers.std"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "bzl",
    desc = [[Bzl langauge server provides intellisense features for BUILD,
BUILD.bazel, WORKSPACE, *.bzl and related files.]],
    homepage = "https://bzl.io",
    languages = { Pkg.Lang.Bazel },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        std.download_file(
            coalesce(
                when(platform.is.mac_x64, "https://get.bzl.io/darwin_amd64/bzl"),
                when(platform.is.linux_x64, "https://get.bzl.io/linux_amd64/bzl"),
                when(platform.is.win_x64, "https://get.bzl.io/windows_amd64/bzl.exe")
            ),
            platform.is.win and "bzl.exe" or "bzl"
        )
        ctx.receipt:with_primary_source { type = "unmanaged" }
        std.chmod("+x", { "bzl" })
        ctx:link_bin("bzl", platform.is.win and "bzl.exe" or "bzl")
    end,
}
