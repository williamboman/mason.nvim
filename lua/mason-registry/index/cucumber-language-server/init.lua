local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "cucumber-language-server",
    desc = [[Cucumber Language Server]],
    homepage = "https://github.com/cucumber/language-server",
    languages = { Pkg.Lang.Cucumber },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@cucumber/language-server", bin = { "cucumber-language-server" } },
}
