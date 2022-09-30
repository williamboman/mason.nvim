local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "remark-cli",
    desc = [[Command line interface to inspect and change markdown files with remark.]],
    homepage = "https://github.com/remarkjs/remark/tree/main/packages/remark-cli",
    languages = { Pkg.Lang.Markdown },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "remark-cli", bin = { "remark" } },
}
