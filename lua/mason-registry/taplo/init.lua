local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"

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
        local asset_file = coalesce(
            when(platform.is.mac, "taplo-full-x86_64-apple-darwin-gnu.tar.gz"),
            when(platform.is.linux_x64, "taplo-full-x86_64-unknown-linux-gnu.tar.gz")
        )
        if asset_file then
            github
                .untargz_release_file({
                    repo = "tamasfe/taplo",
                    asset_file = asset_file,
                })
                .with_receipt()
            ctx:link_bin("taplo", "taplo")
        else
            cargo
                .install("taplo-cli", {
                    features = "lsp,toml-test",
                    bin = { "taplo" },
                })
                .with_receipt()
        end
    end,
}
