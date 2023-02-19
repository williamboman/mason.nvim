local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "golangci-lint-langserver",
    desc = [[golangci-lint language server]],
    homepage = "https://github.com/nametake/golangci-lint-langserver",
    languages = { Pkg.Lang.Go },
    categories = { Pkg.Cat.LSP },
    install = go.packages { "github.com/nametake/golangci-lint-langserver", bin = { "golangci-lint-langserver" } },
}
