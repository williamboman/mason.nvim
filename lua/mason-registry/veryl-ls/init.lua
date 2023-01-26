local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "veryl-ls",
    desc = [[Veryl language server]],
    homepage = "https://github.com/dalance/veryl",
    languages = { Pkg.Lang.Veryl },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("veryl-ls", {
        bin = { "veryl-ls" },
    }),
}
