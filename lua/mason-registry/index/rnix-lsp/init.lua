local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "rnix-lsp",
    desc = [[Language Server for Nix]],
    homepage = "https://github.com/nix-community/rnix-lsp",
    languages = { Pkg.Lang.Nix },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("rnix-lsp", {
        bin = { "rnix-lsp" },
    }),
}
