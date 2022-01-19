local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local context = require "nvim-lsp-installer.installers.context"
local std = require "nvim-lsp-installer.installers.std"

return function(name, root_dir)
    local server_script = [[
using LanguageServer, SymbolServer

maybe_dirname = x -> x !== nothing ? dirname(x) : nothing

OLD_DEPOT_PATH = ARGS[1]
SYMBOLSTORE_PATH = ARGS[2]

runserver(stdin,
          stdout,
          something(maybe_dirname(Base.current_project(pwd())),
                    maybe_dirname(Base.load_path_expand("@v#.#"))),
          OLD_DEPOT_PATH,
          nothing,
          SYMBOLSTORE_PATH)
]]

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/julia-vscode/LanguageServer.jl",
        languages = { "julia" },
        installer = {
            std.ensure_executables {
                { "julia", "julia was not found in path, refer to https://julialang.org/downloads/." },
            },
            context.use_github_release_file("julia-vscode/julia-vscode", function(version)
                local version_number = version:gsub("^v", "")
                return ("language-julia-%s.vsix"):format(version_number)
            end),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file, "vscode-package")
            end),
            std.rename(
                path.concat {
                    "vscode-package",
                    "extension",
                    "scripts",
                },
                "scripts"
            ),
            std.rmrf "vscode-package",
            std.write_file("nvim-lsp.jl", server_script),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source(receipt.github_release_file(ctx))
            end),
        },
        default_options = {
            cmd = {
                "julia",
                "--startup-file=no",
                "--history-file=no",
                "--depwarn=no",
                ("--project=%s"):format(path.concat { root_dir, "scripts", "environments", "languageserver" }),
                path.concat { root_dir, "nvim-lsp.jl" },
                vim.env.JULIA_DEPOT_PATH or "",
                path.concat { root_dir, "symbolstorev5" },
            },
            cmd_env = {
                JULIA_DEPOT_PATH = path.concat { root_dir, "lsdepot" },
            },
        },
    }
end
