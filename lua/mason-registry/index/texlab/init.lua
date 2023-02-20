local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "texlab",
    desc = [[An implementation of the Language Server Protocol for LaTeX]],
    homepage = "https://github.com/latex-lsp/texlab",
    categories = { Pkg.Cat.LSP },
    languages = { Pkg.Lang.LaTeX },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "latex-lsp/texlab"
        platform.when {
            unix = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.is.mac_arm64, "texlab-aarch64-macos.tar.gz"),
                            when(platform.is.mac_x64, "texlab-x86_64-macos.tar.gz"),
                            when(platform.is.linux_x64, "texlab-x86_64-linux.tar.gz")
                        ),
                    })
                    .with_receipt()
                ctx:link_bin("texlab", "texlab")
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = coalesce(when(platform.arch == "x64", "texlab-x86_64-windows.zip")),
                    })
                    .with_receipt()
                ctx:link_bin("texlab", "texlab.exe")
            end,
        }
    end,
}
