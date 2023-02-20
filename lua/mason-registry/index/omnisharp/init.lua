local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "omnisharp",
    desc = _.dedent [[
        OmniSharp language server based on Roslyn workspaces. This version of Omnisharp requires dotnet (.NET 6.0) to be
        installed.
    ]],
    homepage = "https://github.com/OmniSharp/omnisharp-roslyn",
    languages = { Pkg.Lang["C#"] },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "OmniSharp/omnisharp-roslyn",
                asset_file = coalesce(
                    when(platform.is.mac_x64, "omnisharp-osx-x64-net6.0.zip"),
                    when(platform.is.mac_arm64, "omnisharp-osx-arm64-net6.0.zip"),
                    when(platform.is.linux_x64, "omnisharp-linux-x64-net6.0.zip"),
                    when(platform.is.linux_arm64, "omnisharp-linux-arm64-net6.0.zip"),
                    when(platform.is.win_x64, "omnisharp-win-x64-net6.0.zip"),
                    when(platform.is.win_arm64, "omnisharp-win-arm64-net6.0.zip")
                ),
            })
            .with_receipt()

        ctx:link_bin(
            "omnisharp",
            ctx:write_shell_exec_wrapper(
                "omnisharp",
                ("dotnet %q"):format(path.concat {
                    ctx.package:get_install_path(),
                    "OmniSharp.dll",
                })
            )
        )
    end,
}
