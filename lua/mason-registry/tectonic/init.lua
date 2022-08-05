local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "tectonic",
    desc = [[Tectonic is a modernized, complete, self-contained TeX/LaTeX engine, powered by XeTeX and TeXLive.]],
    homepage = "https://tectonic-typesetting.github.io",
    languages = { Pkg.Lang.LaTeX },
    categories = { Pkg.Cat.LSP, Pkg.Cat.Compiler, Pkg.Cat.Runtime },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "tectonic-typesetting/tectonic"
        local function format_release_file(file)
            return _.compose(_.format(file), _.gsub("^tectonic@", ""))
        end

        platform.when {
            unix = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.is.mac, format_release_file "tectonic-%s-x86_64-apple-darwin.tar.gz"),
                            when(
                                platform.is.linux_x64,
                                format_release_file "tectonic-%s-x86_64-unknown-linux-gnu.tar.gz"
                            ),
                            when(
                                platform.is.linux_arm,
                                format_release_file "tectonic-%s-arm-unknown-linux-musleabihf.tar.gz"
                            )
                        ),
                    })
                    .with_receipt()
                std.chmod("+x", { "tectonic" })
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = format_release_file "tectonic-%s-x86_64-pc-windows-gnu.zip",
                    })
                    .with_receipt()
            end,
        }
        ctx:link_bin("tectonic", platform.is.win and "tectonic.exe" or "tectonic")
    end,
}
