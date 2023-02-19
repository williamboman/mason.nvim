local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "ember-language-server",
    desc = [[Language Server Protocol implementation for Ember.js and Glimmer projects]],
    homepage = "https://github.com/lifeart/ember-language-server",
    languages = { Pkg.Lang.Ember },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@lifeart/ember-language-server", bin = { "ember-language-server" } },
}
