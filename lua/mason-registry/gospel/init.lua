local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "gospel",
    desc = [[misspelled word linter for Go comments, string literals and embedded files]],
    homepage = "https://github.com/kortschak/gospel",
    categories = { Pkg.Cat.Linter },
    languages = { Pkg.Lang.Go },
    install = go.packages { "github.com/kortschak/gospel", bin = { "gospel" } },
}
