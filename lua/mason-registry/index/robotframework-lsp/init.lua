local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "robotframework-lsp",
    desc = [[Language Server Protocol implementation for Robot Framework]],
    homepage = "https://github.com/robocorp/robotframework-lsp",
    languages = { Pkg.Lang["Robot Framework"] },
    categories = { Pkg.Cat.LSP },
    install = pip3.packages { "robotframework-lsp", bin = { "robotframework_ls" } },
}
