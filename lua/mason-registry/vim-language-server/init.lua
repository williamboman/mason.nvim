local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "vim-language-server",
    desc = [[VimScript language server.]],
    homepage = "https://github.com/iamcco/vim-language-server",
    languages = { Pkg.Lang.VimScript },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "vim-language-server", bin = { "vim-language-server" } },
}
