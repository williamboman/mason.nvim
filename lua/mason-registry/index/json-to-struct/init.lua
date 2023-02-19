local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "json-to-struct",
    desc = [[A simple command-line tool for generating to struct definitions from JSON]],
    homepage = "https://github.com/tmc/json-to-struct",
    categories = {},
    languages = { Pkg.Lang.Go },
    install = go.packages { "github.com/tmc/json-to-struct", bin = { "json-to-struct" } },
}
