local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local std = require "nvim-lsp-installer.core.managers.std"
local github = require "nvim-lsp-installer.core.managers.github"
local platform = require "nvim-lsp-installer.core.platform"
local fs = require "nvim-lsp-installer.core.fs"
local _ = require "nvim-lsp-installer.core.functional"

return function(name, root_dir)
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
            on_new_config = function(config, new_root_dir)
                local env_path = config.julia_env_path and vim.fn.expand(config.julia_env_path)
                if not env_path then
                    local file_exists = _.compose(fs.sync.file_exists, path.concat, _.concat { new_root_dir })
                    if file_exists { "Project.toml" } and file_exists { "Manifest.toml" } then
                        env_path = new_root_dir
                    elseif file_exists { "JuliaProject.toml" } and file_exists { "JuliaManifest.toml" } then
                        env_path = new_root_dir
                    end
                end

                if not env_path then
                    local ok, env = pcall(vim.fn.system, {
                        "julia",
                        "--startup-file=no",
                        "--history-file=no",
                        "-e",
                        "using Pkg; print(dirname(Pkg.Types.Context().env.project_file))",
                    })
                    if ok then
                        env_path = env
                    end
                end

                config.cmd = {
                    "julia",
                    "--startup-file=no",
                    "--history-file=no",
                    "--depwarn=no",
                    ("--project=%s"):format(path.concat { root_dir, "scripts", "environments", "languageserver" }),
                    path.concat { root_dir, "nvim-lsp.jl" },
                    vim.env.JULIA_DEPOT_PATH or "",
                    path.concat { root_dir, "symbolstorev5" },
                    env_path,
                }
            end,
            cmd_env = {
                JULIA_DEPOT_PATH = path.concat { root_dir, "lsdepot" },
                JULIA_LOAD_PATH = platform.is.win and ";" or ":",
            },
        },
    }
end
