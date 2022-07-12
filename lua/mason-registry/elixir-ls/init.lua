local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "elixir-ls",
    desc = [[A frontend-independent IDE "smartness" server for Elixir. Implements the "Language Server Protocol" standard and provides debugger support via the "Debug Adapter Protocol"]],
    homepage = "https://github.com/elixir-lsp/elixir-ls",
    languages = { Pkg.Lang.Elixir },
    categories = { Pkg.Cat.LSP, Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "elixir-lsp/elixir-ls",
                asset_file = "elixir-ls.zip",
            })
            .with_receipt()

        ctx:link_bin("elixir-ls", platform.is.win and "language_server.bat" or "language_server.sh")
    end,
}
