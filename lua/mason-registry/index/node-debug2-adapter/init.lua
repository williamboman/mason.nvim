local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local git = require "mason-core.managers.git"
local _ = require "mason-core.functional"
local path = require "mason-core.path"
local Optional = require "mason-core.optional"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "node-debug2-adapter",
    desc = [[A debug adapter that supports debugging Node via the Chrome Debugging Protocol. No longer maintained.]],
    homepage = "https://github.com/microsoft/vscode-node-debug2",
    languages = { Pkg.Lang.JavaScript, Pkg.Lang.TypeScript },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local source = github.tag { repo = "microsoft/vscode-node-debug2" }
        source.with_receipt()
        git.clone { "https://github.com/microsoft/vscode-node-debug2", version = Optional.of(source.tag) }
        ctx.spawn.npm { "install" }
        local node_env = platform
            .get_node_version()
            :map(_.cond {
                { _.prop_satisfies(_.gte(18), "major"), _.always { NODE_OPTIONS = "--no-experimental-fetch" } },
                { _.T, _.always {} },
            })
            :get_or_else {}
        ctx.spawn.npm { "run", "build", env = node_env }
        ctx.spawn.npm { "install", "--production" }
        ctx:link_bin(
            "node-debug2-adapter",
            ctx:write_node_exec_wrapper("node-debug2-adapter", path.concat { "out", "src", "nodeDebug.js" })
        )
    end,
}
