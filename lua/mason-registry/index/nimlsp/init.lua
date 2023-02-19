local Pkg = require "mason-core.package"
local git = require "mason-core.managers.git"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local Optional = require "mason-core.optional"

return Pkg.new {
    name = "nimlsp",
    desc = [[Language Server Protocol implementation for Nim]],
    homepage = "https://github.com/PMunch/nimlsp",
    languages = { Pkg.Lang.Nim },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local source = github.tag { repo = "PMunch/nimlsp" }
        source.with_receipt()
        git.clone { "https://github.com/PMunch/nimlsp", version = Optional.of(source.tag) }
        ctx.spawn.nimble { "build", "-y", "--localdeps" }
        ctx:link_bin("nimlsp", platform.is.win and "nimlsp.exe" or "nimlsp")
    end,
}
