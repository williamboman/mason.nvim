local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

local github_url = "https://github.com/wgsl-analyzer/wgsl-analyzer"

return Pkg.new {
    name = "wgsl-analyzer",
    desc = [[A language server implementation for the WGSL shading language]],
    homepage = github_url,
    languages = { Pkg.Lang.WGSL },
    categories = { Pkg.Cat.LSP },
    install = cargo.crate("wgsl_analyzer", {
        git = github_url,
        bin = { "wgsl_analyzer" },
    }),
}
