local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "dockerfile-language-server",
    desc = [[A language server for Dockerfiles powered by Node.js, TypeScript, and VSCode technologies.]],
    homepage = "https://github.com/rcjsuen/dockerfile-language-server-nodejs",
    languages = { Pkg.Lang.Dockerfile },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "dockerfile-language-server-nodejs", bin = { "docker-langserver" } },
}
