local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "nxls",
    desc = [[A language server that provides code completion and more for Nx workspaces.]],
    homepage = "https://github.com/nrwl/nx-console/tree/master/apps/nxls",
    languages = {
        Pkg.Lang.JSON,
    },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "nxls", bin = { "nxls" } },
}
