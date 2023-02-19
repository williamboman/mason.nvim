local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "yaml-language-server",
    desc = [[Language Server for YAML Files]],
    homepage = "https://github.com/redhat-developer/yaml-language-server",
    languages = { Pkg.Lang.YAML },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "yaml-language-server", bin = { "yaml-language-server" } },
}
