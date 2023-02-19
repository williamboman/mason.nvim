local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "omnisharp-mono",
    desc = _.dedent [[
        OmniSharp language server based on Roslyn workspaces. This version of Omnisharp requires Mono to be installed on
        Linux & macOS.
    ]],
    homepage = "https://github.com/OmniSharp/omnisharp-roslyn",
    languages = { Pkg.Lang["C#"] },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        platform.when {
            unix = function()
                github
                    .untargz_release_file({
                        repo = "OmniSharp/omnisharp-roslyn",
                        asset_file = coalesce(
                            when(platform.is.mac, "omnisharp-osx.tar.gz"),
                            when(platform.is.linux_x64, "omnisharp-linux-x64.tar.gz"),
                            when(platform.is.linux_x86, "omnisharp-linux-x86.tar.gz")
                        ),
                    })
                    .with_receipt()
                ctx:link_bin("omnisharp-mono", ctx:write_exec_wrapper("omnisharp-mono", "run"))
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = "OmniSharp/omnisharp-roslyn",
                        asset_file = coalesce(
                            when(platform.is.win_x64, "omnisharp-win-x64.zip"),
                            when(platform.is.win_x86, "omnisharp-win-x86.zip")
                        ),
                    })
                    .with_receipt()
                ctx:link_bin("omnisharp-mono", "OmniSharp.exe")
            end,
        }
    end,
}
