local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "solhint",
    desc = [[Solhint is a linting utility for Solidity code]],
    homepage = "https://protofire.github.io/solhint/",
    languages = { Pkg.Lang.Solidity },
    categories = { Pkg.Cat.Linter },
    install = npm.packages { "solhint", bin = { "solhint" } },
}
