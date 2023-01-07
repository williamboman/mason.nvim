local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local github_client = require "mason-core.managers.github.client"
local Optional = require "mason-core.optional"
local path = require "mason-core.path"
local _ = require "mason-core.functional"

local JAR_FILE = "abl-lsp.jar"
return Pkg.new {
    name = "openedge-language-server",
    desc = _.dedent [[
        OpenEdge Language Server
    ]],
    homepage = "https://github.com/vscode-abl/vscode-abl",
    languages = { Pkg.Lang.Progress },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "vscode-abl/vscode-abl",
                out_file = "abl-lsp.jar",
                asset_file = "abl-lsp.jar",
            })
            .with_receipt()
    end,
}
