local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "ruff",
    desc = [[An extremely fast Python linter, written in Rust.]],
    homepage = "https://github.com/charliermarsh/ruff/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "ruff", bin = { "ruff" } },
}
