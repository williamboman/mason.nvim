local Pkg = require "mason-core.package"
local cargo = require "mason-core.managers.cargo"

return Pkg.new {
    name = "shellharden",
    desc = [[The corrective bash syntax highlighter]],
    homepage = "https://github.com/anordal/shellharden",
    languages = { Pkg.Lang.Bash },
    categories = { Pkg.Cat.Formatter, Pkg.Cat.Linter },
    install = cargo.crate("shellharden", { bin = { "shellharden" } }),
}
