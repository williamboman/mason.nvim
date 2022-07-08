local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "vetur-vls",
    desc = [[VLS (Vue Language Server) is a language server implementation compatible with Language Server Protocol.]],
    homepage = "https://github.com/vuejs/vetur",
    languages = { Pkg.Lang.Vue },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "vls", bin = { "vls" } },
}
