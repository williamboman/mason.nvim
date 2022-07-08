local Pkg = require "mason.core.package"
local platform = require "mason.core.platform"
local _ = require "mason.core.functional"
local github = require "mason.core.managers.github"
local std = require "mason.core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "omnisharp-roslyn",
    desc = [[OmniSharp server (HTTP, STDIO) based on Roslyn workspaces]],
    homepage = "https://github.com/OmniSharp/omnisharp-roslyn",
    languages = { Pkg.Lang["C#"] },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        ctx.fs:mkdir "omnisharp"
        ctx:chdir("omnisharp", function()
            github.unzip_release_file {
                repo = "OmniSharp/omnisharp-roslyn",
                asset_file = coalesce(
                    when(platform.is.mac_x64, "omnisharp-osx-x64-net6.0.zip"),
                    when(platform.is.mac_arm64, "omnisharp-osx-arm64-net6.0.zip"),
                    when(platform.is.linux_x64, "omnisharp-linux-x64-net6.0.zip"),
                    when(platform.is.linux_arm64, "omnisharp-linux-arm64-net6.0.zip"),
                    when(platform.is.win_x64, "omnisharp-win-x64-net6.0.zip"),
                    when(platform.is.win_arm64, "omnisharp-win-arm64-net6.0.zip")
                ),
            }
        end)

        ctx.fs:mkdir "omnisharp-mono"
        ctx:chdir("omnisharp-mono", function()
            github
                .unzip_release_file({
                    repo = "OmniSharp/omnisharp-roslyn",
                    asset_file = "omnisharp-mono.zip",
                })
                .with_receipt()
        end)
    end,
}
