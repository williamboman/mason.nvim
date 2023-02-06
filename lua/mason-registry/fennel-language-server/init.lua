local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

local github_repo = "https://github.com/rydesun/fennel-language-server"
return Pkg.new {
    name = "fennel-language-server",
    desc = [[Fennel language server protocol (LSP) support. ]],
    homepage = github_repo,
    languages = { Pkg.Lang.Fennel },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("fennel-language-server", {
        git = {
            url = github_repo,
        },
        bin = { "fennel-language-server" },
    }),
}

