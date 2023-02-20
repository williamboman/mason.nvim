local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "buf-language-server",
    desc = [[`bufls` is a prototype for the beginnings of a Protobuf language server compatible with Buf modules and workspaces.]],
    homepage = "https://github.com/bufbuild/buf-language-server",
    languages = { Pkg.Lang.Protobuf },
    categories = { Pkg.Cat.LSP },
    install = go.packages {
        "github.com/bufbuild/buf-language-server/cmd/bufls",
        bin = { "bufls" },
    },
}
