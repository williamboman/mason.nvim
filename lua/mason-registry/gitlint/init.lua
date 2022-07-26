local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "gitlint",
    desc = [[Gitlint is a git commit message linter written in python: it checks your commit messages for style.]],
    homepage = "https://jorisroovers.com/gitlint/",
    languages = { Pkg.Lang.GitCommit },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "gitlint", bin = { "gitlint" } },
}
