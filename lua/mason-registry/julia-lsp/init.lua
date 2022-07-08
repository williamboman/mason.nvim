local Pkg = require "mason.core.package"
local path = require "mason.core.path"
local std = require "mason.core.managers.std"
local github = require "mason.core.managers.github"

local server_script = [[
using LanguageServer, SymbolServer, Pkg

OLD_DEPOT_PATH = ARGS[1]
SYMBOLSTORE_PATH = ARGS[2]
ENV_PATH = ARGS[3]

runserver(
    stdin,
    stdout,
    ENV_PATH,
    OLD_DEPOT_PATH,
    nothing,
    SYMBOLSTORE_PATH
)
]]

return Pkg.new {
    name = "julia-lsp",
    desc = [[An implementation of the Microsoft Language Server Protocol for the Julia language.]],
    homepage = "https://github.com/julia-vscode/LanguageServer.jl",
    languages = { Pkg.Lang.Julia },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        std.ensure_executable("julia", { help_url = "https://julialang.org/downloads/" })

        ctx.fs:mkdir "vscode-package"
        ctx:chdir("vscode-package", function()
            github
                .unzip_release_file({
                    repo = "julia-vscode/julia-vscode",
                    asset_file = function(version)
                        local version_number = version:gsub("^v", "")
                        return ("language-julia-%s.vsix"):format(version_number)
                    end,
                })
                .with_receipt()
        end)

        ctx.fs:rename(
            path.concat {
                "vscode-package",
                "extension",
                "scripts",
            },
            "scripts"
        )
        ctx.fs:rmrf "vscode-package"

        ctx.fs:write_file("nvim-lsp.jl", server_script)
    end,
}
