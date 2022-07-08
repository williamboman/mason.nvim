local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "delve",
    desc = [[Delve is a debugger for the Go programming language.]],
    homepage = "https://github.com/go-delve/delve",
    languages = { Pkg.Lang.Go },
    categories = { Pkg.Cat.DAP },
    install = go.packages { "github.com/go-delve/delve/cmd/dlv", bin = { "dlv" } },
}
