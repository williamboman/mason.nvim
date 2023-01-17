local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "gitui",
    desc = [[Blazing 💥 fast terminal-ui for git written in rust 🦀]],
    homepage = "https://github.com/extrawurst/gitui",
    languages = {},
    categories = { Pkg.Cat.Runtime },
    install = function(ctx)
        github
            .untargz_release_file({
                repo = "extrawurst/gitui",
                out_file = "gitui",
                asset_file = coalesce(
                    when(platform.is.mac, "gitui-mac.tar.gz"),
                    when(platform.is.linux_x64, "gitui-linux-musl.tar.gz")
                ),
            })
            :with_receipt()
        std.chmod("+x", { "gitui" })
        ctx:link_bin("gitui", "gitui")
    end,
}
