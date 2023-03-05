local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"
local path = require "mason-core.path"

return Pkg.new {
    name = "azure-pipelines-language-server",
    desc = [[Azure Pipelines Language Server]],
    homepage = "https://github.com/microsoft/azure-pipelines-language-server",
    languages = { Pkg.Lang.AzurePipelines },
    categories = { Pkg.Cat.LSP },
    install = function(ctx)
        npm.packages { "azure-pipelines-language-server" }()
        ctx:link_bin(
            "azure-pipelines-language-server",
            ctx:write_node_exec_wrapper(
                "azure-pipelines-language-server",
                path.concat { "node_modules", "azure-pipelines-language-server", "out", "server.js" }
            )
        )
    end,
}
