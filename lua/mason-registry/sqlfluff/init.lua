local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "sqlfluff",
    desc = [[SQLFluff is a dialect-flexible and configurable SQL linter]],
    homepage = "https://github.com/sqlfluff/sqlfluff",
    languages = { Pkg.Lang.SQL },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "sqlfluff", bin = { "sqlfluff" } },
}
