local Pkg = require "mason-core.package"
local dotnet = require "mason-core.managers.dotnet"

return Pkg.new {
    name = "csharp-language-server",
    desc = [[Roslyn-based LSP language server for C#]],
    homepage = "https://github.com/razzmatazz/csharp-language-server",
    languages = { Pkg.Lang["C#"] },
    categories = { Pkg.Cat.LSP },
    install = dotnet.package("csharp-ls", { bin = { "csharp-ls" } }),
}
