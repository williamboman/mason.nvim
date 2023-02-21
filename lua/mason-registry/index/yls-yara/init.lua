local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "yls-yara",
    desc = [[Language Server for YARA Files]],
    homepage = "https://pypi.org/project/yls-yara/",
    languages = { Pkg.Lang.Yara },
    categories = { Pkg.Cat.LSP },
    install = pip3.packages { "yls-yara", bin = { "yls" } },
}
