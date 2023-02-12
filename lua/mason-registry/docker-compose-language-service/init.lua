local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "docker-compose-language-service",
    desc = [[A language server for Docker Compose.]],
    homepage = "https://github.com/microsoft/compose-language-service",
    languages = { Pkg.Lang.YAML },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@microsoft/compose-language-service" },
}

