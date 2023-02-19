local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "svls",
    desc = [[SystemVerilog language server]],
    homepage = "https://github.com/dalance/svls",
    languages = { Pkg.Lang.SystemVerilog },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("svls", {
        bin = { "svls" },
    }),
}
