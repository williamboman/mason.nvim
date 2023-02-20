local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "rustywind",
    desc = [[CLI for organizing Tailwind CSS classes]],
    homepage = "https://github.com/avencera/rustywind",
    languages = {
        Pkg.Lang.JavaScript,
        Pkg.Lang.TypeScript,
        Pkg.Lang.JSX,
        Pkg.Lang.HTML,
        Pkg.Lang.Vue,
        Pkg.Lang.Angular,
    },
    categories = { Pkg.Cat.Formatter },
    install = npm.packages { "rustywind", bin = { "rustywind" } },
}
