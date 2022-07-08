local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "lemmy-help",
    desc = [[Every one needs help, so lemmy-help you! A CLI to generate vim/nvim help doc from emmylua]],
    homepage = "https://github.com/numToStr/lemmy-help",
    categories = {},
    languages = { Pkg.Lang.Lua },
    install = cargo.crate("lemmy-help", {
        features = "cli",
        bin = { "lemmy-help" },
    }),
}
