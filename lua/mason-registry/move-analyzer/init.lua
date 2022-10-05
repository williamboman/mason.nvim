local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "move-analyzer",
    desc = [[move-analyzer is a language server implementation for the Move programming language.]],
    homepage = "https://github.com/move-language/move",
    languages = { Pkg.Lang.Move },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("move-analyzer", {
        git = {
            url = "https://github.com/move-language/move",
        },
        bin = { "move-analyzer" },
    }),
}
