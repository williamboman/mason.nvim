local Pkg = require "mason-core.package"
local dotnet = require "mason-core.managers.dotnet"

return Pkg.new {
    name = "fsautocomplete",
    desc = [[F# language server using Language Server Protocol]],
    languages = { Pkg.Lang["F#"] },
    categories = { Pkg.Cat.LSP },
    homepage = "https://github.com/fsharp/FsAutoComplete",
    install = dotnet.package("fsautocomplete", {
        bin = { "fsautocomplete" },
    }),
}
