local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "selene",
    desc = [[A blazing-fast modern Lua linter written in Rust]],
    homepage = "https://kampfkarren.github.io/selene/",
    languages = { Pkg.Lang.Lua, Pkg.Lang.Luau },
    categories = { Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "Kampfkarren/selene",
                asset_file = function(release)
                    local target = coalesce(
                        when(platform.is.mac, "selene-%s-macos.zip"),
                        when(platform.is.linux_x64, "selene-%s-linux.zip"),
                        when(platform.is.win_x64, "selene-%s-windows.zip")
                    )
                    return target and target:format(release)
                end,
            })
            .with_receipt()
        std.chmod("+x", { "selene" })
        ctx:link_bin("selene", platform.is.win and "selene.exe" or "selene")
    end,
}
