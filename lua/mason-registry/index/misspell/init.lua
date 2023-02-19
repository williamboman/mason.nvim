local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "misspell",
    desc = [[Correct commonly misspelled English words in source files]],
    homepage = "https://github.com/client9/misspell",
    languages = {},
    categories = { Pkg.Cat.Linter },
    install = go.packages { "github.com/client9/misspell/cmd/misspell", bin = { "misspell" } },
}
