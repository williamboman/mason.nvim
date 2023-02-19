local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local git = require "mason-core.managers.git"
local _ = require "mason-core.functional"
local path = require "mason-core.path"
local Optional = require "mason-core.optional"

return Pkg.new {
    name = "js-debug-adapter",
    desc = [[The VS Code JavaScript debugger]],
    homepage = "https://github.com/microsoft/vscode-js-debug",
    languages = { Pkg.Lang.JavaScript, Pkg.Lang.TypeScript },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local source = github.tag { repo = "microsoft/vscode-js-debug" }
        source.with_receipt()
        git.clone { "https://github.com/microsoft/vscode-js-debug", version = Optional.of(source.tag) }
        ctx.spawn.npm { "install", "--ignore-scripts", "--legacy-peer-deps" }
        ctx.spawn.npm { "run", "compile" }
        ctx.spawn.npm { "install", "--production", "--ignore-scripts", "--legacy-peer-deps" }
        ctx:link_bin(
            "js-debug-adapter",
            ctx:write_node_exec_wrapper("js-debug-adapter", path.concat { "out", "src", "vsDebugServer.js" })
        )
    end,
}
