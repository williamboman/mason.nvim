local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local git = require "mason-core.managers.git"
local _ = require "mason-core.functional"
local path = require "mason-core.path"
local Optional = require "mason-core.optional"

return Pkg.new {
    name = "vscode-js-debug",
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
        ctx.spawn.npm { "install", "--legacy-peer-deps" }
        ctx.spawn.npm { "run", "compile" }
        ctx:link_bin(
            "vscode-js-debug",
            ctx:write_node_exec_wrapper("vscode-js-debug", path.concat { "out", "src", "debugServerMain.js" })
        )
    end,
}
