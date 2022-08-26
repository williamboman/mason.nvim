local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "solidity-language-server",
    desc = [[Solidity language server provides support for autocompletion, snippets, and syntax highlghting on solidity files]],
    homepage = "https://www.npmjs.com/package/solidity-language-server",
    languages = { Pkg.Lang.Solidity },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "solidity-language-server", "graphql", bin = { "solidity-language-server" } },
}
