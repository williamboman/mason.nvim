local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "luau-lsp",
    desc = [[An implementation of a language server for the Luau programming language.]],
    languages = { Pkg.Lang.Luau },
    categories = { Pkg.Cat.LSP },
    homepage = "https://github.com/JohnnyMorganz/luau-lsp",
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "JohnnyMorganz/luau-lsp",
                asset_file = coalesce(
                    when(platform.is.mac, "luau-lsp-macos.zip"),
                    when(platform.is.linux_x64, "luau-lsp-linux.zip"),
                    when(platform.is.win_x64, "luau-lsp-win64.zip")
                ),
            })
            .with_receipt()

        ctx:link_bin("luau-lsp", platform.is.win and "luau-lsp.exe" or "luau-lsp")
    end,
}
