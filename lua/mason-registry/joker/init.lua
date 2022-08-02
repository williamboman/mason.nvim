local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "joker",
    desc = [[Small Clojure interpreter, linter and formatter]],
    homepage = "https://github.com/candid82/joker",
    languages = { Pkg.Lang.Clojure, Pkg.Lang.ClojureScript },
    categories = { Pkg.Cat.Formatter, Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local function format_release_file(file)
            return _.compose(_.format(file), _.gsub("^v", ""))
        end

        github
            .unzip_release_file({
                repo = "candid82/joker",
                asset_file = coalesce(
                    when(platform.is.mac, format_release_file "joker-%s-mac-amd64.zip"),
                    when(platform.is.linux_x64, format_release_file "joker-%s-linux-amd64.zip"),
                    when(platform.is.win_x64, format_release_file "joker-%s-win-amd64.zip")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "joker" })
        ctx:link_bin("joker", platform.is.win and "joker.exe" or "joker")
    end,
}
