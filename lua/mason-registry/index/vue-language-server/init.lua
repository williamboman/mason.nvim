local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "vue-language-server",
    desc = [[⚡ Explore high-performance tooling for Vue]],
    homepage = "https://github.com/johnsoncodehk/volar",
    languages = { Pkg.Lang.Vue },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@volar/vue-language-server", "typescript", bin = { "vue-language-server" } },
}
