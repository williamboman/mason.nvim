local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"
local path = require "mason-core.path"

return Pkg.new {
    name = "rakunavigator",
    desc = [[Raku Language Server that includes Raku critic and code navigation]],
    homepage = "https://github.com/bscan/RakuNavigator",
    languages = { Pkg.Lang.Raku },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        npm.packages { "raku-navigator-server" }()
        ctx:link_bin(
            "rakunavigator",
            ctx:write_node_exec_wrapper(
                "rakunavigator",
                path.concat { "node_modules", "raku-navigator-server", "out", "server.js" }
            )
        )
    end,
}
