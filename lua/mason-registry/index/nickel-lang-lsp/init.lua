local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "nickel-lang-lsp",
    desc = _.dedent [[
        The Nickel Language Server (NLS) is a language server for the Nickel programming language. NLS offers error
        messages, type hints, and auto-completion right in your favorite LSP-enabled editor.
    ]],
    homepage = "https://nickel-lang.org/",
    languages = { Pkg.Lang.Nickel },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("nickel-lang-lsp", {
        bin = { "nls" },
    }),
}
