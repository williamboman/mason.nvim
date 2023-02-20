local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "prisma-language-server",
    desc = _.dedent [[
        Any editor that is compatible with the Language Server Protocol can create clients that can use the features
        provided by this language server.
    ]],
    homepage = "https://github.com/prisma/language-tools",
    languages = { Pkg.Lang.Prisma },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@prisma/language-server", bin = { "prisma-language-server" } },
}
