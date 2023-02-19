local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "colorgen-nvim",
    desc = [[Blazingly fast colorscheme generator for Neovim written in Rust]],
    homepage = "https://github.com/ChristianChiarulli/colorgen-nvim",
    languages = {},
    categories = { Pkg.Cat.Compiler },
    install = cargo.crate("colorgen-nvim", {
        git = {
            url = "https://github.com/ChristianChiarulli/colorgen-nvim",
            tag = false,
        },
        bin = { "colorgen-nvim" },
    }),
}
