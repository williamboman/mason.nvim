local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "goimports-reviser",
    desc = _.dedent [[
        Tool for Golang to sort goimports by 3-4 groups: std, general, company (optional), and project dependencies.
        Also, formatting for your code will be prepared (so, you don't need to use gofmt or goimports separately).
        Use additional option -rm-unused to remove unused imports and -set-alias to rewrite import aliases for
        versioned packages.
    ]],
    homepage = "https://pkg.go.dev/github.com/incu6us/goimports-reviser",
    categories = { Pkg.Cat.Formatter },
    languages = { Pkg.Lang.Go },
    install = go.packages { "github.com/incu6us/goimports-reviser", bin = { "goimports-reviser" } },
}
