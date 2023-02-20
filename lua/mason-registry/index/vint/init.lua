local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "vint",
    desc = [[Fast and Highly Extensible Vim script Language Lint implemented in Python.]],
    homepage = "https://github.com/Vimjas/vint",
    languages = { Pkg.Lang.VimScript },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "vim-vint", bin = { "vint" } },
}
