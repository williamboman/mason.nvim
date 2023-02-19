local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "revive",
    desc = [[~6x faster, stricter, configurable, extensible, and beautiful drop-in replacement for golint]],
    homepage = "https://github.com/mgechev/revive",
    categories = { Pkg.Cat.Linter },
    languages = { Pkg.Lang.Go },
    install = go.packages { "github.com/mgechev/revive", bin = { "revive" } },
}
