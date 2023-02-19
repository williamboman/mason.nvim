local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "clarity-lsp",
    desc = [[Language Server Protocol implementation for Clarity.]],
    homepage = "https://github.com/hirosystems/clarity-lsp",
    languages = { Pkg.Lang.Clarity },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "hirosystems/clarity-lsp",
                asset_file = coalesce(
                    when(platform.is.mac, "clarity-lsp-macos-x64.zip"),
                    when(platform.is.linux_x64, "clarity-lsp-linux-x64.zip"),
                    when(platform.is.win_x64, "clarity-lsp-windows-x64.zip")
                ),
            })
            .with_receipt()
        ctx:link_bin("clarity-lsp", platform.is.win and "clarity-lsp.exe" or "clarity-lsp")
    end,
}
