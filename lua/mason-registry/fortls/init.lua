local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "fortls",
    desc = [[fortls - Fortran Language Server]],
    homepage = "https://github.com/gnikit/fortls",
    languages = { Pkg.Lang.Fortran },
    categories = { Pkg.Cat.LSP },
    install = pip3.packages { "fortls", bin = { "fortls" } },
}
