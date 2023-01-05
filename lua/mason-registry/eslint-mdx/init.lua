local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "eslint-mdx",
    desc = _.dedent [[
        ESLint Parser/Plugin for MDX, helps you lint all ES syntaxes. Linting code blocks can be
        enabled with mdx/code-blocks setting too! Work perfectly with eslint-plugin-import,
        eslint-plugin-prettier or any other eslint plugins. And also can be integrated with
        remark-lint plugins to lint markdown syntaxes.
    ]],
    homepage = "https://github.com/mdx-js/eslint-mdx",
    languages = { Pkg.Lang.JavaScript, Pkg.Lang.Markdown },
    categories = { Pkg.Cat.Linter },
    install = npm.packages { "eslint-plugin-mdx", bin = { "eslint-plugin-mdx" } },
}
