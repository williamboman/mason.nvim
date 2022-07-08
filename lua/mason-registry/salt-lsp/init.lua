local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "salt-lsp",
    desc = [[Salt Language Server Protocol Server]],
    languages = { Pkg.Lang.Salt },
    categories = { Pkg.Cat.LSP },
    homepage = "https://github.com/dcermak/salt-lsp",
    install = pip3.packages { "salt-lsp", bin = { "salt_lsp_server" } },
}
