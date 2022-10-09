local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "iferr",
    desc = [[Go tool to generate if err != nil block for the current function.]],
    homepage = "https://github.com/koron/iferr",
    categories = {},
    languages = { Pkg.Lang.Go },
    install = go.packages { "github.com/koron/iferr", bin = { "iferr" } },
}
