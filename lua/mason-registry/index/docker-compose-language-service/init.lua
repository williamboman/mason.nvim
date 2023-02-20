local Pkg = require "mason-core.package"
local path = require "mason-core.path"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "docker-compose-language-service",
    desc = [[A language server for Docker Compose.]],
    homepage = "https://github.com/microsoft/compose-language-service",
    languages = { Pkg.Lang.Docker },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@microsoft/compose-language-service", bin = { "docker-compose-langserver" } },
}
