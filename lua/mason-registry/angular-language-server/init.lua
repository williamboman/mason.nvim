local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "angular-language-server",
    desc = _.dedent [[
        The Angular Language Service provides code editors with a way to get completions, errors, hints, and navigation
        inside Angular templates. It works with external templates in separate HTML files, and also with in-line
        templates.
    ]],
    homepage = "https://angular.io/guide/language-service",
    languages = { Pkg.Lang.Angular },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@angular/language-server", "typescript", bin = { "ngserver" } },
}
