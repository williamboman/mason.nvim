local Optional = require "mason-core.optional"
local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"

return Pkg.new {
    name = "drools-lsp",
    desc = [[An implementation of a language server for the Drools Rule Language.]],
    homepage = "https://github.com/kiegroup/drools-lsp",
    languages = { Pkg.Lang.Drools },
    categories = { Pkg.Cat.LSP },
    ---@async
    install = function()
        local jar = "drools-lsp-server-jar-with-dependencies.jar"
        github
            .download_release_file({
                repo = "kiegroup/drools-lsp",
                version = Optional.of "latest",
                asset_file = jar,
                out_file = jar,
            })
            .with_receipt()
    end,
}
