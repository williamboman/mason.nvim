local Pkg = require "mason-core.package"
local git = require "mason-core.managers.git"
local path = require "mason-core.path"

return Pkg.new {
    name = "raku-navigator",
    desc = [[Raku Language Server that includes Raku critic and code navigation]],
    homepage = "https://github.com/bscan/RakuNavigator",
    languages = { Pkg.Lang.Raku },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        git.clone({ "https://github.com/bscan/RakuNavigator" }).with_receipt()
        ctx.spawn.npm { "install" }
        ctx.spawn.npm { "run", "compile" }
        ctx:link_bin(
            "raku-navigator",
            ctx:write_node_exec_wrapper("raku-navigator", path.concat { "server", "out", "server.js" })
        )
    end,
}
