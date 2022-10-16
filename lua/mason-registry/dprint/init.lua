local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "dprint",
    desc = [[A pluggable and configurable code formatting platform written in Rust.]],
    homepage = "https://dprint.dev/",
    languages = {},
    categories = { Pkg.Cat.Formatter },
    install = npm.packages { "dprint", bin = { "dprint" } },
}
