local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "proselint",
    desc = _.dedent [[
        proselint is a linter for English prose. It places the world's greatest writers and editors by your side, where
        they whisper suggestions on how to improve your prose.
    ]],
    homepage = "https://github.com/amperser/proselint",
    languages = { Pkg.Lang.Text, Pkg.Lang.Markdown },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "proselint", bin = { "proselint" } },
}
