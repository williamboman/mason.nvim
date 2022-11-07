local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "rustfmt",
    desc = [[A tool for formatting Rust code according to style guidelines]],
    homepage = "https://github.com/rust-lang/rustfmt",
    categories = { Pkg.Cat.Formatter },
    languages = { Pkg.Lang.Rust },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        platform.when {
            unix = function()
                local source = github.untargz_release_file {
                    repo = "rust-lang/rustfmt",
                    asset_file = coalesce(
                        when(platform.is.mac, _.format "rustfmt_macos-x86_64_%s.tar.gz"),
                        when(platform.is.linux_x64, _.format "rustfmt_linux-x86_64_%s.tar.gz")
                    ),
                }
                source.with_receipt()
                ctx:link_bin("rustfmt", path.concat { source.asset_file:gsub("%.tar%.gz$", ""), "rustfmt" })
            end,
            win = function()
                local source = github.unzip_release_file {
                    repo = "rust-lang/rustfmt",
                    asset_file = coalesce(when(platform.is.win_x64, _.format "rustfmt_windows-x86_64-msvc_%s.zip")),
                }
                source.with_receipt()
                ctx:link_bin("rustfmt", path.concat { source.asset_file:gsub("%.zip$", ""), "rustfmt.exe" })
            end,
        }
    end,
}
