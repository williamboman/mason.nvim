local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"
local path = require "mason-core.path"

return Pkg.new {
    name = "perlnavigator",
    desc = [[Perl Language Server that includes perl critic and code navigation]],
    homepage = "https://github.com/bscan/PerlNavigator",
    languages = { Pkg.Lang.Perl },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        npm.packages { "perlnavigator-server" }()
        ctx:link_bin(
            "perlnavigator",
            ctx:write_node_exec_wrapper(
                "perlnavigator",
                path.concat { "node_modules", "perlnavigator-server", "out", "server.js" }
            )
        )
    end,
}
