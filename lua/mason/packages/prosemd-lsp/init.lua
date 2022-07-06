local Pkg = require "mason.core.package"
local platform = require "mason.core.platform"
local _ = require "mason.core.functional"
local github = require "mason.core.managers.github"
local std = require "mason.core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "prosemd-lsp",
    desc = [[An experimental proofreading and linting language server for markdown files ✍️]],
    homepage = "https://github.com/kitten/prosemd-lsp",
    languages = { Pkg.Lang.Markdown },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github.download_release_file({
            repo = "kitten/prosemd-lsp",
            out_file = platform.is_win and "prosemd-lsp.exe" or "prosemd-lsp",
            asset_file = coalesce(
                when(platform.is_mac, "prosemd-lsp-macos"),
                when(platform.is_linux and platform.arch == "x64", "prosemd-lsp-linux"),
                when(platform.is_win and platform.arch == "x64", "prosemd-lsp-windows.exe")
            ),
        }).with_receipt()
        std.chmod("+x", { "prosemd-lsp" })
        ctx:link_bin("prosemd-lsp", platform.is.win and "prosemd-lsp.exe" or "prosemd-lsp")
    end,
}
