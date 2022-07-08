local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "svelte-language-server",
    desc = [[A language server (implementing the language server protocol) for Svelte.]],
    languages = { Pkg.Lang.Svelte },
    categories = { Pkg.Cat.LSP },
    homepage = "https://github.com/sveltejs/language-tools",
    install = npm.packages { "svelte-language-server", bin = { "svelteserver" } },
}
