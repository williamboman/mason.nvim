local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "remark-language-server",
    desc = [[A language server to lint and format markdown files with remark]],
    homepage = "https://github.com/remarkjs/remark-language-server",
    languages = { Pkg.Lang.Markdown },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "remark-language-server", bin = { "remark-language-server" } },
}
