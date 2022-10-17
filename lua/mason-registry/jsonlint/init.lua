local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "jsonlint",
    desc = [[A pure JavaScript version of the service provided at jsonlint.com.]],
    homepage = "https://github.com/zaach/jsonlint",
    languages = {
        Pkg.Lang.JSON,
    },
    categories = { Pkg.Cat.Linter },
    install = npm.packages { "jsonlint", bin = { "jsonlint" } },
}
