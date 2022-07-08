local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "serve-d",
    desc = [[Microsoft language server protocol implementation for D using workspace-d]],
    homepage = "https://github.com/Pure-D/serve-d",
    languages = { Pkg.Lang.D },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "Pure-D/serve-d"
        platform.when {
            unix = function()
                github
                    .untarxz_release_file({
                        repo = repo,
                        asset_file = function(release)
                            local target = coalesce(
                                when(platform.is.mac, "serve-d_%s-osx-x86_64.tar.xz"),
                                when(platform.is.linux_x64, "serve-d_%s-linux-x86_64.tar.xz")
                            )
                            return target and target:format(release:gsub("^v", ""))
                        end,
                    })
                    .with_receipt()
                ctx:link_bin("serve-d", "serve-d")
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = function(release)
                            local target = coalesce(
                                when(platform.arch == "x64", "serve-d_%s-windows-x86_64.zip"),
                                when(platform.arch == "x86", "serve-d_%s-windows-x86.zip")
                            )
                            return target and target:format(release:gsub("^v", ""))
                        end,
                    })
                    .with_receipt()
                ctx:link_bin("serve-d", "serve-d.exe")
            end,
        }
    end,
}
