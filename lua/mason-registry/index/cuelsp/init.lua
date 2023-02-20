local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "cuelsp",
    desc = [[Language Server implementation for CUE, with built-in support for Dagger.]],
    homepage = "https://github.com/dagger/cuelsp",
    languages = { Pkg.Lang.Cue },
    categories = { Pkg.Cat.LSP },
    install = go.packages { "github.com/dagger/cuelsp/cmd/cuelsp", bin = { "cuelsp" } },
}
