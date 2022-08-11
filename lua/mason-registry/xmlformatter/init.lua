local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "xmlformatter",
    desc = [[Provides formatting of XML documents.]],
    homepage = "https://github.com/pamoller/xmlformatter",
    languages = { Pkg.Lang.XML },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "xmlformatter", bin = { "xmlformat" } },
}
