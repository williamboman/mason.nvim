local Pkg = require "mason-core.package"
local dotnet = require "mason-core.managers.dotnet"

return Pkg.new {
    name = "csharpier",
    desc = [[CSharpier is an opinionated code formatter for c#]],
    homepage = "https://csharpier.com",
    languages = { Pkg.Lang["C#"] },
    categories = { Pkg.Cat.Formatter },
    install = dotnet.package("csharpier", { bin = { "dotnet-csharpier" } }),
}
