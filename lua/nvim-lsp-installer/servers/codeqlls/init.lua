local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"
local context = require "nvim-lsp-installer.installers.context"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    ---@param search_path string|nil
    ---@return string[]
    local function create_cmd(search_path)
        local cmd = {
            path.concat { root_dir, "codeql", platform.is_win and "codeql.cmd" or "codeql" },
            "execute",
            "language-server",
            "--check-errors",
            "ON_CHANGE",
            "-q",
        }
        if search_path then
            table.insert(cmd, search_path)
        end
        return cmd
    end

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "codeql" },
        installer = {
            context.use_github_release_file(
                "github/codeql-cli-binaries",
                coalesce(
                    when(platform.is_mac, "codeql-osx64.zip"),
                    when(platform.is_unix, "codeql-linux64.zip"),
                    when(platform.is_win, "codeql-win64.zip")
                )
            ),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
        },
        default_options = {
            cmd = create_cmd(),
            on_new_config = function(config)
                if
                    type(config.settings.search_path) == "table" and not vim.tbl_isempty(config.settings.search_path)
                then
                    local search_path = "--search-path="
                    for _, path_entry in ipairs(config.settings.search_path) do
                        search_path = search_path .. vim.fn.expand(path_entry) .. ":"
                    end
                    config.cmd = create_cmd(search_path)
                else
                    config.cmd = create_cmd()
                end
            end,
        },
    }
end
