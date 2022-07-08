local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "sqls",
    desc = [[SQL language server written in Go.]],
    homepage = "https://github.com/lighttiger2505/sqls",
    languages = { Pkg.Lang.SQL },
    categories = { Pkg.Cat.LSP },
    install = go.packages { "github.com/lighttiger2505/sqls", bin = { "sqls" } },
}
