local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "smarty-language-server",
    desc = [[Language Server Protocol implementation for Smarty.]],
    homepage = "https://github.com/landeaux/vscode-smarty-langserver-extracted",
    languages = { Pkg.Lang.Smarty },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "vscode-smarty-langserver-extracted", bin = { "smarty-language-server" } },
}
