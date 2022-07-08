local Pkg = require "mason.core.package"
local go = require "mason.core.managers.go"

return Pkg.new {
    name = "gotests",
    desc = [[Gotests is a Golang commandline tool that generates table driven tests based on its target source files' function and method signatures.]],
    homepage = "https://github.com/cweill/gotests",
    categories = {},
    languages = { Pkg.Lang.Go },
    install = go.packages { "github.com/cweill/gotests/...", bin = { "gotests" } },
}
