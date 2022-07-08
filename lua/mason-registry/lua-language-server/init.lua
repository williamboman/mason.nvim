local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "lua-language-server",
    desc = [[Lua Language Server]],
    languages = { Pkg.Lang.Lua },
    categories = { Pkg.Cat.LSP },
    homepage = "https://github.com/sumneko/lua-language-server",
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "sumneko/vscode-lua",
                asset_file = function(version)
                    local target = coalesce(
                        when(platform.is.mac_x64, "vscode-lua-%s-darwin-x64.vsix"),
                        when(platform.is.mac_arm64, "vscode-lua-%s-darwin-arm64.vsix"),
                        when(platform.is.linux_x64, "vscode-lua-%s-linux-x64.vsix"),
                        when(platform.is.linux_arm64, "vscode-lua-%s-linux-arm64.vsix"),
                        when(platform.is.win_x64, "vscode-lua-%s-win32-x64.vsix"),
                        when(platform.is.win_x86, "vscode-lua-%s-win32-ia32.vsix")
                    )

                    return target and target:format(version)
                end,
            })
            .with_receipt()

        platform.when {
            unix = function()
                ctx:link_bin(
                    "lua-language-server",
                    ctx:write_exec_wrapper(
                        "lua-language-server",
                        path.concat {
                            "extension",
                            "server",
                            "bin",
                            "lua-language-server",
                        }
                    )
                )
            end,
            win = function()
                ctx:link_bin(
                    "lua-language-server",
                    path.concat {
                        "extension",
                        "server",
                        "bin",
                        "lua-language-server.exe",
                    }
                )
            end,
        }
    end,
}
