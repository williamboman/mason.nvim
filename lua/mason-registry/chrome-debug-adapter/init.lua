local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local git = require "mason-core.managers.git"
local _ = require "mason-core.functional"
local path = require "mason-core.path"
local Optional = require "mason-core.optional"

return Pkg.new {
    name = "chrome-debug-adapter",
    desc = [[Debug your JavaScript code running in Google Chrome.]],
    homepage = "https://github.com/Microsoft/vscode-chrome-debug",
    languages = { Pkg.Lang.JavaScript, Pkg.Lang.TypeScript },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local source = github.tag { repo = "Microsoft/vscode-chrome-debug" }
        source.with_receipt()
        git.clone { "https://github.com/Microsoft/vscode-chrome-debug", version = Optional.of(source.tag) }
        ctx.spawn.npm { "install" }
        ctx.spawn.npm { "run", "build" }
        ctx.spawn.npm { "install", "--production", "--ignore-scripts" }
        -- vscode-chrome-debug comes with a lot of extra baggage
        ctx.fs:rmrf "images"
        ctx.fs:rmrf "testdata"
        ctx.fs:rmrf ".git"
        ctx:link_bin(
            "chrome-debug-adapter",
            ctx:write_node_exec_wrapper("chrome-debug-adapter", path.concat { "out", "src", "chromeDebug.js" })
        )
    end,
}
