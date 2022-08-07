local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "yamllint",
    desc = _.dedent [[
        Linter for YAML files. yamllint does not only check for syntax validity, but for weirdnesses like key repetition
        and cosmetic problems such as lines length, trailing spaces, indentation, etc.
    ]],
    homepage = "https://github.com/adrienverge/yamllint",
    languages = { Pkg.Lang.YAML },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "yamllint", bin = { "yamllint" } },
}
