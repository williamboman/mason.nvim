local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "impl",
    desc = [[impl generates method stubs for implementing an interface.]],
    homepage = "https://github.com/josharian/impl",
    categories = {},
    languages = { Pkg.Lang.Go },
    install = go.packages { "github.com/josharian/impl", bin = { "impl" } },
}
