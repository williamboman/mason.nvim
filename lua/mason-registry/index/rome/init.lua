local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "rome",
    desc = [[Rome is a formatter, linter, bundler, and more for JavaScript, TypeScript, JSON, HTML, Markdown, and CSS.]],
    homepage = "https://rome.tools",
    languages = { Pkg.Lang.TypeScript, Pkg.Lang.JavaScript },
    categories = { Pkg.Cat.LSP, Pkg.Cat.Linter },
    install = npm.packages { "rome", bin = { "rome" } },
}
