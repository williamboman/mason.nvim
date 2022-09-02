local Pkg = require "mason-core.package"
local dotnet = require "mason-core.managers.dotnet"

return Pkg.new {
    name = "fantomas",
    desc = [[Fantomas is an opinionated code formatter for f#]],
    homepage = "https://fsprojects.github.io/fantomas",
    languages = { Pkg.Lang["F#"] },
    categories = { Pkg.Cat.Formatter },
    install = dotnet.package("fantomas", { bin = { "fantomas" } }),
}
