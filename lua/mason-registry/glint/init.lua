local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "glint",
    desc = _.dedent [[
        Glint is a set of tools to aid in developing code that uses the Glimmer VM for rendering, such as
        Ember.js v3.24+ and GlimmerX projects. Similar to Vetur for Vue projects or Svelte Language Tools, Glint
        consists of a CLI and a language server to provide feedback and enforce correctness both locally during editing
        and project-wide in CI.
    ]],
    homepage = "https://typed-ember.gitbook.io/glint/",
    categories = { Pkg.Cat.LSP, Pkg.Cat.Linter },
    languages = {
        Pkg.Lang.Handlebars,
        Pkg.Lang.Glimmer,
        Pkg.Lang.TypeScript,
        Pkg.Lang.JavaScript,
    },
    install = npm.packages { "@glint/core", "typescript", bin = { "glint", "glint-language-server" } },
}
