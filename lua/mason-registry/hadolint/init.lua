local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "hadolint",
    desc = [[Dockerfile linter, validate inline bash, written in Haskell]],
    homepage = "https://github.com/hadolint/hadolint",
    languages = { Pkg.Lang.Dockerfile },
    categories = { Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "hadolint/hadolint",
                out_file = platform.is.win and "hadolint.exe" or "hadolint",
                asset_file = coalesce(
                    when(platform.is.mac, "hadolint-Darwin-x86_64"),
                    when(platform.is.linux_arm64, "hadolint-Linux-arm64"),
                    when(platform.is.linux_x64, "hadolint-Linux-x86_64"),
                    when(platform.is.win_x64, "hadolint-Windows-x86_64.exe")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "hadolint" })
        ctx:link_bin("hadolint", platform.is.win and "hadolint.exe" or "hadolint")
    end,
}
