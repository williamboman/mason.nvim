local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "staticcheck",
    desc = [[The advanced Go linter]],
    homepage = "https://staticcheck.io/",
    categories = { Pkg.Cat.Linter },
    languages = { Pkg.Lang.Go },
    install = go.packages { "honnef.co/go/tools/cmd/staticcheck", bin = { "staticcheck" } },
}
