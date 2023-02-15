local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "vacuum",
    desc = _.dedent [[
        vacuum is the worlds fastest OpenAPI 3, OpenAPI 2 / Swagger linter and quality analysis tool.
        Built in go, it tears through API specs faster than you can think.
        vacuum is compatible with Spectral rulesets and generates compatible reports.
    ]],
    homepage = "https://github.com/daveshanley/vacuum",
    languages = { Pkg.Lang.OpenAPI },
    categories = { Pkg.Cat.Linter },
    install = npm.packages { "@quobix/vacuum", bin = { "vacuum" } },
}
