local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

local github_url = "https://github.com/move-language/move"

-- cargo install --git https://github.com/move-language/move move-analyzer 

return Pkg.new {
    name = "move-analyzer",
    desc = [[
    Move is a programming language for writing safe smart contracts originally developed at Facebook to power the Diem blockchain.
    ]],
    homepage = github_url,
    languages = { Pkg.Lang.Move },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("move-analyzer", {
        git = github_url,
        bin = { "move_analyzer" },
    }),
}
