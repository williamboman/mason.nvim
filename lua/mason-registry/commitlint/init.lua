local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "commitlint",
    desc = "commitlint checks if your commit messages meet the conventional commit format.",
    homepage = "https://commitlint.js.org/",
    languages = { Pkg.Lang.GitCommit },
    categories = { Pkg.Cat.Linter },
    install = npm.packages {
        "@commitlint/cli",
        "@commitlint/config-conventional",
        "commitlint-format-json",
        bin = { "commitlint" },
    },
}
