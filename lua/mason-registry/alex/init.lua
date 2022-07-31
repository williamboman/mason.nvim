local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "alex",
    desc = [[Catch insensitive, inconsiderate writing]],
    homepage = "https://github.com/get-alex/alex",
    languages = { Pkg.Lang.Markdown },
    categories = { Pkg.Cat.Linter },
    install = npm.packages { "alex", bin = { "alex" } },
}
