local Pkg = require "mason-core.package"
local gem = require "mason-core.managers.gem"

return Pkg.new {
    name = "ruby-lsp",
    desc = [[This gem is an implementation of the language server protocol specification for Ruby, used to improve editor features.]],
    homepage = "https://github.com/Shopify/ruby-lsp",
    languages = { Pkg.Lang.Ruby },
    categories = { Pkg.Cat.LSP },
    install = gem.packages { "ruby-lsp", bin = { "ruby-lsp" } },
}
