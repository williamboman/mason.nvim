local path = require "mason-core.path"
local platform = require "mason-core.platform"
local fs = require "mason-core.fs"
local _ = require "mason-core.functional"

---@param config table
return function(config)
    local install_dir = config["install_dir"]

    return {
        on_new_config = function(config, workspace_dir)
            local env_path = config.julia_env_path and vim.fn.expand(config.julia_env_path)
            if not env_path then
                local file_exists = _.compose(fs.sync.file_exists, path.concat, _.concat { workspace_dir })
                if file_exists { "Project.toml" } and file_exists { "Manifest.toml" } then
                    env_path = workspace_dir
                elseif file_exists { "JuliaProject.toml" } and file_exists { "JuliaManifest.toml" } then
                    env_path = workspace_dir
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
                ("--project=%s"):format(path.concat { install_dir, "scripts", "environments", "languageserver" }),
                path.concat { install_dir, "nvim-lsp.jl" },
                vim.env.JULIA_DEPOT_PATH or "",
                path.concat { install_dir, "symbolstorev5" },
                env_path,
            }
        end,
        cmd_env = {
            JULIA_DEPOT_PATH = path.concat { install_dir, "lsdepot" },
            JULIA_LOAD_PATH = platform.is.win and ";" or ":",
        },
    }
end
