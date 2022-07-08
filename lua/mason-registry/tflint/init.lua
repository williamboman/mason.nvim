local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "tflint",
    desc = [[A Pluggable Terraform Linter]],
    homepage = "https://github.com/terraform-linters/tflint",
    languages = { Pkg.Lang.Terraform },
    categories = { Pkg.Cat.LSP, Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "terraform-linters/tflint",
                asset_file = coalesce(
                    when(platform.is.mac_x64, "tflint_darwin_amd64.zip"),
                    when(platform.is.mac_arm64, "tflint_darwin_arm64.zip"),
                    when(platform.is.linux_x64, "tflint_linux_amd64.zip"),
                    when(platform.is.linux_arm64, "tflint_linux_arm64.zip"),
                    when(platform.is.linux_x86, "tflint_linux_386.zip"),
                    when(platform.is.win_x64, "tflint_windows_amd64.zip")
                ),
            })
            .with_receipt()
        ctx:link_bin("tflint", platform.is.win and "tflint.exe" or "tflint")
    end,
}
