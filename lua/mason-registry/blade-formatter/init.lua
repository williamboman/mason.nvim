local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "blade-formatter",
    desc = [[An opinionated blade template formatter for Laravel that respects readability]],
    homepage = "https://github.com/shufo/blade-formatter",
    languages = { Pkg.Lang.Blade },
    categories = { Pkg.Cat.Formatter },
    install = npm.packages { "blade-formatter", bin = { "blade-formatter" } },
}
