local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "golangci-lint",
    desc = _.dedent [[
        golangci-lint is a fast Go linters runner. It runs linters in parallel, uses caching, supports yaml config, has
        integrations with all major IDE and has dozens of linters included.
    ]],
    homepage = "https://golangci-lint.run/",
    languages = { Pkg.Lang.Go },
    categories = { Pkg.Cat.Linter },
    install = go.packages { "github.com/golangci/golangci-lint/cmd/golangci-lint", bin = { "golangci-lint" } },
}
