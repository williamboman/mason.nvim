local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "nginx-language-server",
    desc = [[A language server for nginx configuration files.]],
    homepage = "https://github.com/pappasam/nginx-language-server",
    languages = { Pkg.Lang.Nginx },
    categories = { Pkg.Cat.LSP },
    install = pip3.packages { "nginx-language-server", bin = { "nginx-language-server" } },
}
