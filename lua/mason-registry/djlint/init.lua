local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "djlint",
    desc = [[HTML Template Linter and Formatter. Django - Jinja - Nunjucks - Handlebars - GoLang]],
    homepage = "https://github.com/Riverside-Healthcare/djLint",
    languages = { Pkg.Lang.HTMLDjango },
    categories = { Pkg.Cat.Formatter, Pkg.Cat.Linter },
    install = pip3.packages { "djlint", bin = { "djlint" } },
}
