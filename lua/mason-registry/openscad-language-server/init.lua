local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "openscad-language-server",
    desc = [[Language Server Protocol implementation for OpenSCAD, written in Rust.]],
    homepage = "https://github.com/Leathong/openscad-LSP",
    languages = { Pkg.Lang.Openscad },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("openscad-lsp", {
        bin = { "openscad-lsp" },
    }),
}
