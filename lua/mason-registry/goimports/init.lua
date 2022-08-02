local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "goimports",
    desc = [[A golang formatter which formats your code in the same style as gofmt and additionally updates your Go import lines]],
    homepage = "https://pkg.go.dev/golang.org/x/tools/cmd/goimports",
    categories = { Pkg.Cat.Formatter },
    languages = { Pkg.Lang.Go },
    install = go.packages { "golang.org/x/tools/cmd/goimports@latest", bin = { "goimports" } },
}
