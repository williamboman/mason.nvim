local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "shfmt",
    desc = [[A shell formatter (sh/bash/mksh)]],
    homepage = "https://github.com/mvdan/sh",
    languages = { Pkg.Lang.Bash, Pkg.Lang.Mksh, Pkg.Lang.Shell },
    categories = { Pkg.Cat.Formatter },
    install = function(ctx)
        github
            .download_release_file({
                repo = "mvdan/sh",
                out_file = platform.is.win and "shfmt.exe" or "shfmt",
                asset_file = coalesce(
                    when(platform.is.mac_arm64, _.format "shfmt_%s_darwin_arm64"),
                    when(platform.is.mac_x64, _.format "shfmt_%s_darwin_amd64"),
                    when(platform.is.linux_arm64, _.format "shfmt_%s_linux_arm64"),
                    when(platform.is.linux_x64, _.format "shfmt_%s_linux_amd64"),
                    when(platform.is.win_x86, _.format "shfmt_%s_windows_386.exe"),
                    when(platform.is.win_x64, _.format "shfmt_%s_windows_amd64.exe")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "shfmt" })
        ctx:link_bin("shfmt", platform.is.win and "shfmt.exe" or "shfmt")
    end,
}
