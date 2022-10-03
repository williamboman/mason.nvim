local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "erg-language-server",
    desc = [[ELS is a language server for the Erg programing language.]],
    homepage = "https://github.com/erg-lang/erg-language-server",
    languages = { Pkg.Lang.Erg },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("els", {
        bin = { "els" },
    }),
}
