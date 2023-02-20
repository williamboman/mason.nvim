local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "fixjson",
    desc = [[A JSON file fixer/formatter for humans using (relaxed) JSON5]],
    homepage = "https://github.com/rhysd/fixjson",
    languages = {
        Pkg.Lang.JSON,
    },
    categories = { Pkg.Cat.Formatter },
    install = npm.packages { "fixjson", bin = { "fixjson" } },
}
