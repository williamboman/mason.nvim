local Pkg = require "mason-core.package"
local dotnet = require "mason-core.managers.dotnet"

return Pkg.new {
    name = "csharp_ls",
    desc = [[C# language server using Language Server Protocol]],
    languages = { Pkg.Lang["C#"] },
    categories = { Pkg.Cat.LSP },
    homepage = "https://github.com/razzmatazz/csharp-language-server",
    install = dotnet.package("csharp-ls", {
        bin = { "csharp-ls" },
    }),
}
