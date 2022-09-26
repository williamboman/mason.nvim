local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "solidity-ls",
    desc = [[Solidity language server.]],
    homepage = "https://github.com/qiuxiang/solidity-ls",
    languages = { Pkg.Lang.Solidity },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "solidity-ls", bin = { "solidity-ls" } },
}
