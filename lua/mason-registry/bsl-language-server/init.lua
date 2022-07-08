local Pkg = require "mason.core.package"
local github = require "mason.core.managers.github"

return Pkg.new {
    name = "bsl-language-server",
    desc = [[Implementation of Language Server Protocol for Language 1C (BSL)]],
    homepage = "https://1c-syntax.github.io/bsl-language-server",
    languages = { Pkg.Lang["1С:Enterprise"], Pkg.Lang.OneScript },
    categories = { Pkg.Cat.LSP },
    ---@async
    install = function()
        github
            .download_release_file({
                repo = "1c-syntax/bsl-language-server",
                out_file = "bsl-lsp.jar",
                asset_file = function(release)
                    local version = release:gsub("^v", "")
                    return ("bsl-language-server-%s-exec.jar"):format(version)
                end,
            })
            .with_receipt()
    end,
}
