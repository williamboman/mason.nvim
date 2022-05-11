local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local std = require "nvim-lsp-installer.core.managers.std"
local github = require "nvim-lsp-installer.core.managers.github"

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
        ---@param ctx InstallContext
        installer = function(ctx)
            std.ensure_executable("julia", { help_url = "https://julialang.org/downloads/" })

            ctx.fs:mkdir "vscode-package"
            ctx:chdir("vscode-package", function()
                github.unzip_release_file({
                    repo = "julia-vscode/julia-vscode",
                    asset_file = function(version)
                        local version_number = version:gsub("^v", "")
                        return ("language-julia-%s.vsix"):format(version_number)
                    end,
                }).with_receipt()
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
