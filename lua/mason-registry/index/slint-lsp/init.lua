local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

return Pkg.new {
    name = "slint-lsp",
    desc = [[A LSP Server that adds features like auto-complete and live preview of the .slint files to many editors.]],
    homepage = "https://slint-ui.com/",
    languages = { Pkg.Lang.Slint },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "slint-ui/slint"
        platform.when {
            win = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = "slint-lsp-windows.zip",
                    })
                    .with_receipt()
            end,
            linux = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = "slint-lsp-linux.tar.gz",
                    })
                    .with_receipt()
            end,
        }
        ctx:link_bin("slint-lsp", path.concat { "slint-lsp", platform.is.win and "slint-lsp.exe" or "slint-lsp" })
    end,
}
