local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "gofumpt",
    desc = [[A stricter gofmt]],
    homepage = "https://pkg.go.dev/mvdan.cc/gofumpt",
    categories = { Pkg.Cat.Formatter },
    languages = { Pkg.Lang.Go },
    install = go.packages { "mvdan.cc/gofumpt", bin = { "gofumpt" } },
}
