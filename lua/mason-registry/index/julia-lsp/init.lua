local Pkg = require "mason-core.package"
local path = require "mason-core.path"
local std = require "mason-core.managers.std"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"

local server_script = [[
if VERSION < v"1.0.0"
    error("julia language server only works with julia 1.0.0+")
end

import Pkg
version_specific_env_path = joinpath(@__DIR__, "scripts", "environments", "languageserver", "v$(VERSION.major).$(VERSION.minor)")
if isdir(version_specific_env_path)
    Pkg.activate(version_specific_env_path)
else
    Pkg.activate(joinpath(@__DIR__, "scripts", "environments", "languageserver", "fallback"))
end

using LanguageServer, SymbolServer, Pkg

OLD_DEPOT_PATH = ARGS[1]
ENV_PATH = ARGS[2]

runserver(
    stdin,
    stdout,
    ENV_PATH,
    OLD_DEPOT_PATH,
    nothing,
    ENV["SYMBOLSTORE_PATH"]
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
        ctx:link_bin(
            "julia-lsp",
            ctx:write_shell_exec_wrapper(
                "julia-lsp",
                ("julia --startup-file=no --history-file=no --depwarn=no %q"):format(path.concat {
                    ctx.package:get_install_path(),
                    "nvim-lsp.jl",
                }),
                {
                    SYMBOLSTORE_PATH = path.concat { ctx.package:get_install_path(), "symbolstorev5" },
                    JULIA_DEPOT_PATH = path.concat { ctx.package:get_install_path(), "lsdepot" },
                    JULIA_LOAD_PATH = platform.is.win and ";" or ":",
                }
            )
        )
    end,
}
