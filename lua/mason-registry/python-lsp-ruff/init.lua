local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "python-lsp-ruff",
    desc = [[Python-lsp-server linter plugin based on ruff - An extremely fast Python linter, written in Rust.]],
    homepage = "https://github.com/python-lsp/python-lsp-ruff",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "python-lsp-ruff", bin = { "python-lsp-ruff" } },
}
