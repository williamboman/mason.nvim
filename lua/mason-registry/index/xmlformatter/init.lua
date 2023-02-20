local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "xmlformatter",
    desc = _.dedent [[
        xmlformatter is an Open Source Python package that provides formatting of XML documents. xmlformatter differs
        from others formatters by handling whitespaces by a distinct set of formatting rules - formatting element
        content by an object style and mixed content by a text style. You may find xmlformatter useful for corrections
        and presentations.
    ]],
    homepage = "https://github.com/pamoller/xmlformatter",
    languages = { Pkg.Lang.XML },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "xmlformatter", bin = { "xmlformat" } },
}
