local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "astro-language-server",
    desc = [[The Astro language server, its structure is inspired by the Svelte Language Server.]],
    homepage = "https://github.com/withastro/language-tools",
    languages = { Pkg.Lang.Astro },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@astrojs/language-server", "typescript", bin = { "astro-ls" } },
}
