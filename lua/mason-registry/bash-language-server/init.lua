local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "bash-language-server",
    desc = [[A language server for Bash]],
    homepage = "https://github.com/bash-lsp/bash-language-server",
    languages = { Pkg.Lang.Bash },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "bash-language-server", bin = { "bash-language-server" } },
}
