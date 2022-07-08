local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "terraform-ls",
    desc = [[Terraform Language Server]],
    homepage = "https://github.com/hashicorp/terraform-ls",
    languages = { Pkg.Lang.Terraform },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "hashicorp/terraform-ls",
                asset_file = function(version)
                    local target = coalesce(
                        when(platform.is.mac_arm64, "terraform-ls_%s_darwin_arm64.zip"),
                        when(platform.is.mac_x64, "terraform-ls_%s_darwin_amd64.zip"),
                        when(platform.is.linux_arm64, "terraform-ls_%s_linux_arm64.zip"),
                        when(platform.is.linux_arm, "terraform-ls_%s_linux_arm.zip"),
                        when(platform.is.linux_x64, "terraform-ls_%s_linux_amd64.zip"),
                        when(platform.is.win_x64, "terraform-ls_%s_windows_amd64.zip")
                    )
                    return target and target:format(version:gsub("^v", ""))
                end,
            })
            .with_receipt()
        ctx:link_bin("terraform-ls", platform.is.win and "terraform-ls.exe" or "terraform-ls")
    end,
}
