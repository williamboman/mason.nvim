local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"
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
        npm.packages { "https://github.com/bscan/RakuNavigator" }()
        ctx:link_bin(
            "raku-navigator",
            ctx:write_node_exec_wrapper(
                "raku-navigator",
                path.concat { "node_modules", "raku-navigator-server", "out", "server.js" }
            )
        )
    end,
}
