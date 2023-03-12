local Optional = require "mason-core.optional"
local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local git = require "mason-core.managers.git"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

return Pkg.new {
    name = "mockdebug",
    desc = _.dedent [[
        Mock Debug simulates a debug adapter. It supports step, continue, breakpoints, exceptions, and variable access
        but it is not connected to any real debugger.
    ]],
    homepage = "https://github.com/microsoft/vscode-mock-debug",
    languages = {},
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local source = github.tag { repo = "microsoft/vscode-mock-debug" }
        source.with_receipt()
        git.clone { "https://github.com/microsoft/vscode-mock-debug", version = Optional.of(source.tag) }
        ctx.spawn.npm { "install" }
        ctx.spawn.npm { "run", "compile" }
        ctx.spawn.npm { "install", "--production" }
        ctx:link_bin(
            "mock-debug-adapter",
            ctx:write_node_exec_wrapper("mock-debug-adapter", path.concat { "out", "debugAdapter.js" })
        )
    end,
}
