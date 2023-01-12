local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local std = require "mason-core.managers.std"

return Pkg.new {
    name = "fourmolu",
    desc = [[A fork of Ormolu that uses four space indentation and allows arbitrary configuration.]],
    homepage = "https://hackage.haskell.org/package/fourmolu",
    languages = { Pkg.Lang.Haskell },
    categories = { Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        ---@param template string
        local function release_file(template_string)
            return _.compose(_.format(template_string), _.gsub("^v", ""))
        end

        github
            .download_release_file({
                repo = "fourmolu/fourmolu",
                out_file = "fourmolu",
                asset_file = _.coalesce(
                    _.when(platform.is.mac_x64, release_file "fourmolu-%s-osx-x86_64"),
                    _.when(platform.is.linux_x64_gnu, release_file "fourmolu-%s-linux-x86_64")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "fourmolu" })
        ctx:link_bin("fourmolu", "fourmolu")
    end,
}
