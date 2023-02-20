local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "prettierd",
    desc = [[Prettier, as a daemon, for ludicrous formatting speed]],
    homepage = "https://github.com/fsouza/prettierd",
    languages = {
        Pkg.Lang.JavaScript,
        Pkg.Lang.TypeScript,
        Pkg.Lang.Flow,
        Pkg.Lang.JSX,
        Pkg.Lang.JSON,
        Pkg.Lang.CSS,
        Pkg.Lang.SCSS,
        Pkg.Lang.LESS,
        Pkg.Lang.HTML,
        Pkg.Lang.Vue,
        Pkg.Lang.Angular,
        Pkg.Lang.GraphQL,
        Pkg.Lang.Markdown,
        Pkg.Lang.YAML,
    },
    categories = { Pkg.Cat.Formatter },
    install = npm.packages { "@fsouza/prettierd", bin = { "prettierd" } },
}
