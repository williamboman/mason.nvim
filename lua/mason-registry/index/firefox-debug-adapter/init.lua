local Optional = require "mason-core.optional"
local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local git = require "mason-core.managers.git"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

return Pkg.new {
    name = "firefox-debug-adapter",
    desc = [[Debug your web application or browser extension in Firefox]],
    homepage = "https://github.com/firefox-devtools/vscode-firefox-debug",
    languages = { Pkg.Lang.JavaScript, Pkg.Lang.TypeScript },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local source = github.tag { repo = "firefox-devtools/vscode-firefox-debug" }
        source.with_receipt()
        git.clone { "https://github.com/firefox-devtools/vscode-firefox-debug", version = Optional.of(source.tag) }
        ctx.spawn.npm { "install" }
        ctx.spawn.npm { "run", "build" }
        ctx.spawn.npm { "install", "--production" }
        ctx:link_bin(
            "firefox-debug-adapter",
            ctx:write_node_exec_wrapper("firefox-debug-adapter", path.concat { "dist", "adapter.bundle.js" })
        )
    end,
}
