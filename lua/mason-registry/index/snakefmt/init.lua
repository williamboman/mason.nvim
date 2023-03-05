local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "snakefmt",
    desc = "The uncompromising Snakemake code formatter",
    homepage = "https://github.com/snakemake/snakefmt",
    languages = { Pkg.Lang.Snakemake },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "snakefmt", bin = { "snakefmt" } },
}
