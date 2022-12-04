local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "ripgrep",
    desc = [[Ripgrep is a line-oriented search tool that recursively searches the current directory.]],
    homepage = "https://github.com/BurntSushi/ripgrep",
    languages = {},
    categories = { Pkg.Cat.Runtime },
    install = function(ctx)
        local repo = "BurntSushi/ripgrep"
        platform.when {
            win = function()
                local source = github.unzip_release_file {
                    repo = repo,
                    asset_file = coalesce(
                        when(platform.is.win_x86, function(version)
                            return ("ripgrep-%s-i686-pc-windows-msvc.zip"):format(version)
                        end),
                        when(platform.is.win_x64, function(version)
                            return ("ripgrep-%s-x86_64-pc-windows-msvc.zip"):format(version)
                        end)
                    ),
                }
                source.with_receipt()
                ctx.fs:rename(source.asset_file:gsub("%.zip$", ""), "ripgrep")
                ctx:link_bin("rg", path.concat { "ripgrep", "rg.exe" }) -- link binary
            end,
            linux = function()
                local source = github.untargz_release_file {
                    repo = repo,
                    asset_file = coalesce(
                        -- @Note: using the x86 build instead of arm which is not available yet
                        when(platform.is.mac_arm64, function(version)
                            return ("ripgrep-%s-x86_64-apple-darwin.tar.gz"):format(version)
                        end),
                        when(platform.is.mac_x64, function(version)
                            return ("ripgrep-%s-x86_64-apple-darwin.tar.gz"):format(version)
                        end),
                        when(platform.is.linux_arm64_gnu, function(version)
                            return ("ripgrep-%s-arm-unknown-linux-gnueabihf.tar.gz"):format(version)
                        end),
                        when(platform.is.linux_x64_musl, function(version)
                            return ("ripgrep-%s-x86_64-unknown-linux-musl.tar.gz"):format(version)
                        end)
                    ),
                }
                source.with_receipt()
                ctx.fs:rename(source.asset_file:gsub("%.tar%.gz$", ""), "ripgrep")
                ctx:link_bin("rg", path.concat { "ripgrep", "rg" }) -- link binary
            end,
        }
    end,
}
