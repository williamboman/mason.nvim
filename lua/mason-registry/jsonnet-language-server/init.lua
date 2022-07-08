local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "jsonnet-language-server",
    desc = [[A Language Server Protocol (LSP) server for Jsonnet (https://jsonnet.org)]],
    homepage = "https://github.com/grafana/jsonnet-language-server",
    languages = { Pkg.Lang.Jsonnet },
    categories = { Pkg.Cat.LSP },
    install = go.packages { "github.com/grafana/jsonnet-language-server", bin = { "jsonnet-language-server" } },
}
