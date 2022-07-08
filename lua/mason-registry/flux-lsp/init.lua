local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "flux-lsp",
    desc = [[Implementation of Language Server Protocol for the Flux language]],
    homepage = "https://github.com/influxdata/flux-lsp",
    languages = { Pkg.Lang.Flux },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("https://github.com/influxdata/flux-lsp", {
        git = true,
        bin = { "flux-lsp" },
    }),
}
