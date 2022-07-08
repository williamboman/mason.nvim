local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "taplo",
    desc = [[A versatile, feature-rich TOML toolkit.]],
    homepage = "https://taplo.tamasfe.dev/",
    languages = { Pkg.Lang.TOML },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("taplo-cli", {
        features = "lsp",
        bin = { "taplo" },
    }),
}
