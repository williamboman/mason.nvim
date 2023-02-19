local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "clang-format",
    desc = [[clang-format is formatter for C/C++/Java/JavaScript/JSON/Objective-C/Protobuf/C# code]],
    homepage = "https://pypi.org/project/clang-format/",
    languages = { Pkg.Lang.C, Pkg.Lang["C++"], Pkg.Lang.Java, Pkg.Lang.JavaScript, Pkg.Lang.JSON, Pkg.Lang["C#"] },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "clang-format", bin = { "clang-format" } },
}
