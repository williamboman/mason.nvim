local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"
local Optional = require "mason-core.optional"

return Pkg.new {
    name = "rome",
    desc = [[Rome is a formatter, linter, bundler, and more for JavaScript, TypeScript, JSON, HTML, Markdown, and CSS.]],
    homepage = "https://rome.tools",
    languages = { Pkg.Lang.TypeScript, Pkg.Lang.JavaScript },
    categories = { Pkg.Cat.LSP, Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        ctx.requested_version = ctx.requested_version:or_(function()
            return Optional.of "10.0.7-nightly.2021.7.27"
        end)
        npm.install({ "rome", bin = { "rome" } }).with_receipt()
    end,
}
