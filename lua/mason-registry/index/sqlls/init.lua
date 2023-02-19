local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "sqlls",
    desc = [[SQL Language Server]],
    homepage = "https://github.com/joe-re/sql-language-server",
    languages = { Pkg.Lang.SQL },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "sql-language-server", bin = { "sql-language-server" } },
}
