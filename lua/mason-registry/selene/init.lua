local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "selene",
    desc = [[A blazing-fast modern Lua linter written in Rust]],
    homepage = "https://kampfkarren.github.io/selene/",
    languages = { Pkg.Lang.Lua },
    categories = { Pkg.Cat.Linter },
    install = cargo.crate { "selene", bin = { "selene" } },
}
