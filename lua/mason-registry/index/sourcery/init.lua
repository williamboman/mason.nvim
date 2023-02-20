local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "sourcery",
    desc = _.dedent [[
        Sourcery is a tool available in your IDE, GitHub, or as a CLI that suggests refactoring improvements to help
        make your code more readable and generally higher quality.
    ]],
    homepage = "https://docs.sourcery.ai/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.LSP },
    install = pip3.packages { "sourcery-cli", bin = { "sourcery" } },
}
