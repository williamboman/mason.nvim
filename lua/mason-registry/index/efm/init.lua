local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "efm",
    desc = [[General purpose Language Server]],
    homepage = "https://github.com/mattn/efm-langserver",
    languages = {},
    categories = { Pkg.Cat.LSP },
    install = go.packages { "github.com/mattn/efm-langserver", bin = { "efm-langserver" } },
}
