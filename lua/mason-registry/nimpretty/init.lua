local Pkg = require "mason-core.package"
local git = require "mason-core.managers.git"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local Optional = require "mason-core.optional"

return Pkg.new {
    name = "nimpretty",
    desc = [[Standard tool for pretty formatting Nim]],
    homepage = "https://github.com/nim-lang/Nim",
    languages = { Pkg.Lang.Nim },
    categories = { Pkg.Cat.Formatter},
}
