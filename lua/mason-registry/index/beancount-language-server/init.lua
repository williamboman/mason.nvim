local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "beancount-language-server",
    desc = [[A Language Server Protocol (LSP) for beancount files]],
    homepage = "https://github.com/polarmutex/beancount-language-server",
    languages = { Pkg.Lang.Beancount },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("beancount-language-server", {
        bin = { "beancount-language-server" },
    }),
}
