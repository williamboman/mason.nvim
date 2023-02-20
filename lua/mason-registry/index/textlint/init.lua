local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "textlint",
    desc = [[The pluggable natural language linter for text and markdown.]],
    homepage = "https://textlint.github.io",
    languages = { Pkg.Lang.Text, Pkg.Lang.Markdown },
    categories = { Pkg.Cat.Linter },
    install = npm.packages { "textlint", bin = { "textlint" } },
}
