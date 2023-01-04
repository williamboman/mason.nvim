local Pkg = require "mason-core.package"
local opam = require "mason-core.managers.opam"

return Pkg.new {
    name = "ocamlformat",
    desc = [[ocamlformat is a tool for formatting OCaml code]],
    homepage = "https://github.com/ocaml-ppx/ocamlformat",
    languages = { Pkg.Lang.OCaml },
    categories = { Pkg.Cat.Formatter },
    install = opam.packages { "ocamlformat", bin = { "ocamlformat" } },
}
