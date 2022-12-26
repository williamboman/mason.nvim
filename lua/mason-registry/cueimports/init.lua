local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "cueimports",
    desc = [[CUE tool that updates your import lines, adding missing ones and removing unused ones.]],
    homepage = "https://github.com/asdine/cueimports",
    languages = { Pkg.Lang.Cue },
    categories = { Pkg.Cat.Formatter },
    install = go.packages { "github.com/asdine/cueimports/cmd/cueimports", bin = { "cueimports" } },
}
