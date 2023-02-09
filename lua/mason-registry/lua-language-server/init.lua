local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "lua-language-server",
    desc = [[A language server that offers Lua language support - programmed in Lua.]],
    languages = { Pkg.Lang.Lua },
    categories = { Pkg.Cat.LSP },
    homepage = "https://github.com/LuaLS/lua-language-server",
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "LuaLS/lua-language-server"
        platform.when {
            unix = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.is.mac_x64, _.format "lua-language-server-%s-darwin-x64.tar.gz"),
                            when(platform.is.mac_arm64, _.format "lua-language-server-%s-darwin-arm64.tar.gz"),
                            when(platform.is.linux_x64_gnu, _.format "lua-language-server-%s-linux-x64.tar.gz"),
                            when(platform.is.linux_arm64_gnu, _.format "lua-language-server-%s-linux-arm64.tar.gz")
                        ),
                    })
                    .with_receipt()

                ctx:link_bin(
                    "lua-language-server",
                    ctx:write_exec_wrapper(
                        "lua-language-server",
                        path.concat {
                            "bin",
                            "lua-language-server",
                        }
                    )
                )
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.is.win_x64, _.format "lua-language-server-%s-win32-x64.zip"),
                            when(platform.is.win_x86, _.format "lua-language-server-%s-win32-ia32.zip")
                        ),
                    })
                    .with_receipt()
                ctx:link_bin(
                    "lua-language-server",
                    path.concat {
                        "bin",
                        "lua-language-server.exe",
                    }
                )
            end,
        }
    end,
}
