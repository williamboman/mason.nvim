local _ = require "mason-core.functional"
local Pkg = require "mason-core.package"
local opam = require "mason-core.managers.opam"

return Pkg.new {
    name = "ocamlformat",
    desc = _.dedent [[
        ocamlformat is a tool for formatting OCaml code. It automatically adjusts the layout of your code to follow the
        recommended style guidelines, making it easier to read and understand.
    ]],
    homepage = "https://github.com/ocaml-ppx/ocamlformat",
    languages = { Pkg.Lang.OCaml },
    categories = { Pkg.Cat.Formatter },
    install = opam.packages { "ocamlformat", bin = { "ocamlformat" } },
}
