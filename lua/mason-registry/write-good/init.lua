local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "write-good",
    desc = [[Naive linter for English prose for developers who can't write good and wanna learn to do other stuff good too.]],
    homepage = "https://github.com/btford/write-good",
    languages = { Pkg.Lang.Markdown },
    categories = { Pkg.Cat.Linter },
    install = npm.packages { "write-good", bin = { "write-good" } },
}
