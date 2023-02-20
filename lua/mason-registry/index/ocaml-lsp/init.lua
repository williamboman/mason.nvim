local Pkg = require "mason-core.package"
local opam = require "mason-core.managers.opam"

return Pkg.new {
    name = "ocaml-lsp",
    desc = [[OCaml Language Server Protocol implementation]],
    homepage = "https://github.com/ocaml/ocaml-lsp",
    languages = { Pkg.Lang.OCaml },
    categories = { Pkg.Cat.LSP },
    install = opam.packages { "ocaml-lsp-server", bin = { "ocamllsp" } },
}
