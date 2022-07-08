local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "cssmodules-language-server",
    desc = [[autocompletion and go-to-defintion for cssmodules]],
    homepage = "https://github.com/antonk52/cssmodules-language-server",
    languages = { Pkg.Lang.CSS },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "cssmodules-language-server", bin = { "cssmodules-language-server" } },
}
