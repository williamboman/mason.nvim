local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "eslint-lsp",
    desc = _.dedent [[
        Language Server Protocol implementation for ESLint. The server uses the ESLint library installed in the opened
        workspace folder. If the folder doesn't provide one the extension looks for a global install version.
    ]],
    homepage = "https://github.com/Microsoft/vscode-eslint",
    languages = { Pkg.Lang.JavaScript, Pkg.Lang.TypeScript },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "vscode-langservers-extracted", bin = { "vscode-eslint-language-server" } },
}
