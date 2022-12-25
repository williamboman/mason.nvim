local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "ruff-lsp",
    desc = [[A Language Server Protocol implementation for Ruff - An extremely fast Python linter, written in Rust.]],
    homepage = "https://github.com/charliermarsh/ruff-lsp/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.LSP },
    install = pip3.packages { "ruff-lsp", bin = { "ruff-lsp" } },
}
