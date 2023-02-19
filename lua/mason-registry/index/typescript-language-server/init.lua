local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "typescript-language-server",
    desc = [[TypeScript & JavaScript Language Server]],
    homepage = "https://github.com/typescript-language-server/typescript-language-server",
    categories = { Pkg.Cat.LSP },
    languages = { Pkg.Lang.TypeScript, Pkg.Lang.JavaScript },
    install = npm.packages { "typescript-language-server", "typescript", bin = { "typescript-language-server" } },
}
