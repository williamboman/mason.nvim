local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "asm-lsp",
    desc = [[Language server for NASM/GAS/GO Assembly]],
    homepage = "https://github.com/bergercookie/asm-lsp",
    languages = { Pkg.Lang.Assembly },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("asm-lsp", {
        bin = { "asm-lsp" },
    }),
}
