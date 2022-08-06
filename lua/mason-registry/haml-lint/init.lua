local Pkg = require "mason-core.package"
local gem = require "mason-core.managers.gem"

return Pkg.new {
    name = "haml-lint",
    desc = [[Tool for writing clean and consistent HAML]],
    homepage = "https://github.com/sds/haml-lint",
    languages = { Pkg.Lang.HAML },
    categories = { Pkg.Cat.Linter },
    install = gem.packages { "haml_lint", bin = { "haml-lint" } },
}
