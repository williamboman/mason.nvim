local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "unocss-language-server",
    desc = [[Language Server Protocol implementation for UnoCSS.]],
    homepage = "https://github.com/xna00/unocss-language-server",
    languages = { Pkg.Lang.CSS },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "unocss-language-server", bin = { "unocss-language-server" } },
}
