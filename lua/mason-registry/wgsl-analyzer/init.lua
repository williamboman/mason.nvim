local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "wgsl-analyzer",
    desc = [[A language server implementation for the WGSL shading language]],
    homepage = "https://github.com/wgsl-analyzer/wgsl-analyzer",
    languages = { Pkg.Lang.WGSL },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("wgsl_analyzer", {
        git = {
            url = "https://github.com/wgsl-analyzer/wgsl-analyzer",
            tag = true,
        },
        bin = { "wgsl_analyzer" },
    }),
}
