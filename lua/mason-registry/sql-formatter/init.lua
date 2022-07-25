local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "sql-formatter",
    desc = [[A whitespace formatter for different query languages]],
    homepage = "https://sql-formatter-org.github.io/sql-formatter/",
    languages = { Pkg.Lang.SQL },
    categories = { Pkg.Cat.Formatter },
    install = npm.packages { "sql-formatter", bin = { "sql-formatter" } },
}
