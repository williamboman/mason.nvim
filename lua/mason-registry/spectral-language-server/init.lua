local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "spectral-language-server",
    desc = _.dedent [[
        Awesome Spectral JSON/YAML linter with OpenAPI/AsyncAPI support. Spectral is a flexible object linter with out
        of the box support for OpenAPI v2 and v3, JSON Schema, and AsyncAPI.
    ]],
    homepage = "https://github.com/luizcorreia/spectral-language-server",
    languages = { Pkg.Lang.JSON, Pkg.Lang.YAML },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "spectral-language-server", bin = { "spectral-language-server" } },
}
