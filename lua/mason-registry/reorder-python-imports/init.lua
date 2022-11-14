local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "reorder-python-imports",
    desc = [[Tool for automatically reordering python imports. Similar to isort but uses static analysis more.]],
    homepage = "https://github.com/asottile/reorder_python_imports",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "reorder-python-imports", bin = { "reorder-python-imports" } },
}
