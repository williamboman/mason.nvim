local Pkg = require "mason-core.package"
local path = require "mason-core.path"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "docker-compose-language-service",
    desc = [[A language server for Docker Compose.]],
    homepage = "https://github.com/microsoft/compose-language-service",
    languages = { Pkg.Lang.Docker },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        npm.install({ "@microsoft/compose-language-service" }).with_receipt()
        ctx:link_bin(
            "docker-compose-language-service",
            ctx:write_node_exec_wrapper(
                "docker-compose-language-service",
                path.concat {
                    "node_modules",
                    "@microsoft",
                    "compose-language-service",
                    "lib",
                    "server.js",
                }
            )
        )
    end,
}
