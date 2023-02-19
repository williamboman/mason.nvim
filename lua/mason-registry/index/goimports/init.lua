local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "goimports",
    desc = _.dedent [[
        A golang formatter which formats your code in the same style as gofmt and additionally updates your Go import
        lines, adding missing ones and removing unreferenced ones.
    ]],
    homepage = "https://pkg.go.dev/golang.org/x/tools/cmd/goimports",
    categories = { Pkg.Cat.Formatter },
    languages = { Pkg.Lang.Go },
    install = go.packages { "golang.org/x/tools/cmd/goimports", bin = { "goimports" } },
}
