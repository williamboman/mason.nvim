local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"

return Pkg.new {
    name = "elixir-ls",
    desc = [[A frontend-independent IDE "smartness" server for Elixir. Implements the "Language Server Protocol" standard and provides debugger support via the "Debug Adapter Protocol"]],
    homepage = "https://github.com/elixir-lsp/elixir-ls",
    languages = { Pkg.Lang.Elixir },
    categories = { Pkg.Cat.LSP, Pkg.Cat.DAP },
    ---@async
    install = function()
        github
            .unzip_release_file({
                repo = "elixir-lsp/elixir-ls",
                asset_file = "elixir-ls.zip",
            })
            .with_receipt()
    end,
}
