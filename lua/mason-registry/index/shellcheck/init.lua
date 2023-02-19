local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "shellcheck",
    desc = [[ShellCheck, a static analysis tool for shell scripts]],
    homepage = "https://www.shellcheck.net/",
    categories = { Pkg.Cat.Linter },
    languages = { Pkg.Lang.Bash },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        platform.when {
            unix = function()
                github
                    .untarxz_release_file({
                        strip_components = 1,
                        repo = "koalaman/shellcheck",
                        asset_file = _.coalesce(
                            _.when(platform.is.mac, _.format "shellcheck-%s.darwin.x86_64.tar.xz"),
                            _.when(platform.is.linux_x64, _.format "shellcheck-%s.linux.x86_64.tar.xz"),
                            _.when(platform.is.linux_arm64, _.format "shellcheck-%s.linux.aarch64.tar.xz"),
                            _.when(platform.is.linux_arm, _.format "shellcheck-%s.linux.armv6hf.tar.xz")
                        ),
                    })
                    .with_receipt()
                ctx:link_bin("shellcheck", "shellcheck")
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = "koalaman/shellcheck",
                        asset_file = _.coalesce(_.when(platform.is.win_x64, _.format "shellcheck-%s.zip")),
                    })
                    .with_receipt()
                ctx:link_bin("shellcheck", "shellcheck.exe")
            end,
        }
    end,
}
