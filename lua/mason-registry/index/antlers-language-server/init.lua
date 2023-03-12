local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "antlers-language-server",
    desc = _.dedent [[
        Provides rich language features for Statamic's Antlers templating language, including code completions, syntax
        highlighting, and more.
    ]],
    homepage = "https://github.com/Stillat/vscode-antlers-language-server",
    languages = { Pkg.Lang.Antlers },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "antlers-language-server", bin = { "antlersls" } },
}
