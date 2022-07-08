local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "python-lsp-server",
    desc = [[Fork of the python-language-server project, maintained by the Spyder IDE team and the community]],
    homepage = "https://github.com/python-lsp/python-lsp-server",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.LSP },
    install = pip3.packages { "python-lsp-server[all]", bin = { "pylsp" } },
}
