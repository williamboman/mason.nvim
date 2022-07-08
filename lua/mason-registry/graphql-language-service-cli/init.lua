local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "graphql-language-service-cli",
    desc = [[GraphQL Language Service provides an interface for building GraphQL language services for IDEs.]],
    homepage = "https://www.npmjs.com/package/graphql-language-service-cli",
    languages = { Pkg.Lang.GraphQL },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "graphql-language-service-cli", "graphql", bin = { "graphql-lsp" } },
}
