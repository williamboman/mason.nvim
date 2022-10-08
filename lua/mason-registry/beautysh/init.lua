local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "beautysh",
    desc = [[beautysh - A Bash beautifier for the masses.]],
    homepage = "https://github.com/lovesegfault/beautysh",
    languages = { Pkg.Lang.Bash },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages {
        "beautysh",
        bin = {
            "beautysh",
        },
    },
}
