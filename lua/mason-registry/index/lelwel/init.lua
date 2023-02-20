local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "lelwel",
    desc = [[LL(1) parser generator for Rust]],
    homepage = "https://github.com/0x2a-42/lelwel",
    languages = { Pkg.Lang.Lelwel },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("lelwel", {
        features = "lsp,cli",
        bin = { "lelwel-ls", "llw" },
    }),
}
