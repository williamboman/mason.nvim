local Pkg = require "mason.core.package"
local github = require "mason.core.managers.github"
local git = require "mason.core.managers.git"
local _ = require "mason.core.functional"
local path = require "mason.core.path"
local Optional = require "mason.core.optional"

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
        ctx.spawn.npm { "run", "build" }
        ctx.spawn.npm { "install", "--production" }
        ctx:write_node_exec_wrapper("node-debug2-adapter", path.concat { "out", "src", "nodeDebug.js" })
        ctx:link_bin("node-debug2-adapter", "node-debug2-adapter")
    end,
}
