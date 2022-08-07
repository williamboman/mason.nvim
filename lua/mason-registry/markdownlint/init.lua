local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "markdownlint",
    desc = [[A Node.js style checker and lint tool for Markdown/CommonMark files]],
    homepage = "https://github.com/igorshubovych/markdownlint-cli",
    languages = { Pkg.Lang.Markdown },
    categories = { Pkg.Cat.Linter, Pkg.Cat.Formatter },
    install = npm.packages { "markdownlint-cli", bin = { "markdownlint" } },
}
