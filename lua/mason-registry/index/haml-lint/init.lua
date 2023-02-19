local Pkg = require "mason-core.package"
local gem = require "mason-core.managers.gem"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "haml-lint",
    desc = _.dedent [[
        haml-lint is a tool to help keep your HAML files clean and readable. In addition to HAML-specific style and lint
        checks, it integrates with RuboCop to bring its powerful static analysis tools to your HAML documents.
    ]],
    homepage = "https://github.com/sds/haml-lint",
    languages = { Pkg.Lang.HAML },
    categories = { Pkg.Cat.Linter },
    install = gem.packages { "haml_lint", bin = { "haml-lint" } },
}
