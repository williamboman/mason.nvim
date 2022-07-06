local Pkg = require "mason.core.package"
local pip3 = require "mason.core.managers.pip3"

return Pkg.new {
    name = "debugpy",
    desc = [[An implementation of the Debug Adapter Protocol for Python]],
    homepage = "https://github.com/microsoft/debugpy",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.DAP },
    install = pip3.packages { "debugpy" },
}
