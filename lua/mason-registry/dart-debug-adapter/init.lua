local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local git = require "mason-core.managers.git"
local _ = require "mason-core.functional"
local path = require "mason-core.path"
local Optional = require "mason-core.optional"

return Pkg.new {
    name = "dart-debug-adapter",
    desc = [[Debug any dart script file or project]],
    homepage = "https://github.com/Dart-Code/Dart-Code",
    languages = { Pkg.Lang.Dart },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local source = github.tag { repo = "Dart-Code/Dart-Code" }
        source.with_receipt()
        git.clone { "https://github.com/Dart-Code/Dart-Code", version = Optional.of(source.tag) }
        ctx.spawn.npm { "install" }
        ctx.spawn.npm { "run", "build" }
        ctx.spawn.npm { "install", "--production" }
        ctx:link_bin(
            "dart-debug-adapter",
            ctx:write_node_exec_wrapper("dart-debug-adapter", path.concat { "out", "dist", "debug.js" })
        )
    end,
}
