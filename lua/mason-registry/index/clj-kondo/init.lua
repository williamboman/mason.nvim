local Pkg = require("mason-core.package")
local _ = require("mason-core.functional")
local platform = require("mason-core.platform")
local github = require("mason-core.managers.github")
local std = require("mason-core.managers.std")

local coalesce, when = _.coalesce, _.when

return Pkg.new({
    name = "clj-kondo",
    desc = [[Static analyzer and linter for Clojure code that sparks joy]],
    homepage = "https://github.com/clj-kondo/clj-kondo",
    languages = { Pkg.Lang.Clojure, Pkg.Lang.ClojureScript },
    categories = { Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local function format_release_file(file)
            return _.compose(_.format(file), _.gsub("^v", ""))
        end

        github
            .unzip_release_file({
                repo = "clj-kondo/clj-kondo",
                asset_file = coalesce(
                    when(platform.is.mac_arm64, format_release_file("clj-kondo-%s-macos-aarch64.zip")),
                    when(platform.is.mac_x64, format_release_file("clj-kondo-%s-macos-amd64.zip")),
                    when(platform.is.linux_x64_musl, format_release_file("clj-kondo-%s-linux-static-amd64.zip")),
                    when(platform.is.linux_x64_gnu, format_release_file("clj-kondo-%s-linux-amd64.zip")),
                    when(platform.is.linux_arm64, format_release_file("clj-kondo-%s-linux-aarch64.zip")),
                    when(platform.is.win_x64, format_release_file("clj-kondo-%s-windows-amd64.zip"))
                ),
            })
            .with_receipt()
        std.chmod("+x", { "clj-kondo" })
        ctx:link_bin("clj-kondo", platform.is.win and "clj-kondo.exe" or "clj-kondo")
    end,
})
