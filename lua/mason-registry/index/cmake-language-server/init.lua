local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "cmake-language-server",
    desc = [[CMake LSP Implementation]],
    homepage = "https://github.com/regen100/cmake-language-server",
    languages = { Pkg.Lang.CMake },
    categories = { Pkg.Cat.LSP },
    install = pip3.packages { "cmake-language-server", bin = { "cmake-language-server" } },
}
