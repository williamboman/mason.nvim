local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local composer = require "mason-core.managers.composer"
local git = require "mason-core.managers.git"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local Optional = require "mason-core.optional"
local path = require "mason-core.path"

return Pkg.new {
    name = "phpactor",
    desc = _.dedent [[
        Phpactor is an intelligent Completion and Refactoring tool for PHP which is available over it’s own RPC protocol
        and as a Language Server.
    ]],
    homepage = "https://phpactor.readthedocs.io/en/master/",
    languages = { Pkg.Lang.PHP },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        assert(platform.is.unix, "phpactor only supports UNIX environments.")
        local source = github.tag { repo = "phpactor/phpactor" }
        source.with_receipt()
        git.clone { "https://github.com/phpactor/phpactor", version = Optional.of(source.tag) }
        composer.install()
        ctx:link_bin("phpactor", path.concat { "bin", "phpactor" })
    end,
}
