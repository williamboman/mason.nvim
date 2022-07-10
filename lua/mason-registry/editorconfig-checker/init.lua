local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "editorconfig-checker",
    desc = [[A tool to verify that your files are in harmony with your `.editorconfig`.]],
    homepage = "https://github.com/editorconfig-checker/editorconfig-checker",
    languages = {},
    categories = { Pkg.Cat.Linter },
    install = go.packages {
        "github.com/editorconfig-checker/editorconfig-checker/cmd/editorconfig-checker",
        bin = { "editorconfig-checker" },
    },
}
