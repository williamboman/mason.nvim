local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "grammarly-languageserver",
    desc = [[A language server implementation on top of Grammarly's SDK.]],
    homepage = "https://github.com/znck/grammarly",
    languages = { Pkg.Lang.Markdown, Pkg.Lang.Text },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "grammarly-languageserver", bin = { "grammarly-languageserver" } },
}
