local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "curlylint",
    desc = [[Experimental HTML templates linting for Jinja, Nunjucks, Django templates, Twig, Liquid]],
    homepage = "https://www.curlylint.org/",
    languages = { Pkg.Lang.Django, Pkg.Lang.Jinja, Pkg.Lang.Nunjucks, Pkg.Lang.Twig, Pkg.Lang.Liquid },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "curlylint", bin = { "curlylint" } },
}
