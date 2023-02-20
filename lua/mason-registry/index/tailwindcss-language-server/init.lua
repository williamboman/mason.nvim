local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "tailwindcss-language-server",
    desc = [[Language Server Protocol implementation for Tailwind CSS.]],
    homepage = "https://github.com/tailwindlabs/tailwindcss-intellisense",
    languages = { Pkg.Lang.CSS },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@tailwindcss/language-server", bin = { "tailwindcss-language-server" } },
}
