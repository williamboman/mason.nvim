local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "stylua",
    desc = [[An opinionated Lua code formatter]],
    homepage = "https://github.com/JohnnyMorganz/StyLua",
    languages = { Pkg.Lang.Lua, Pkg.Lang.Luau },
    categories = { Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "johnnymorganz/stylua",
                asset_file = coalesce(
                    when(platform.is.mac_arm64, "stylua-macos-aarch64.zip"),
                    when(platform.is.mac_x64, "stylua-macos.zip"),
                    when(platform.is.linux_x64, "stylua-linux-x86_64.zip"),
                    when(platform.is.linux_arm64, "stylua-linux-aarch64.zip"),
                    when(platform.is.win_x64, "stylua-win64.zip")
                ),
            })
            .with_receipt()
        ctx:link_bin("stylua", platform.is.win and "stylua.exe" or "stylua")
    end,
}
