local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "diagnostic-languageserver",
    desc = [[Diagnostic language server that integrates with linters.]],
    homepage = "https://github.com/iamcco/diagnostic-languageserver",
    languages = {},
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "diagnostic-languageserver", bin = { "diagnostic-languageserver" } },
}
