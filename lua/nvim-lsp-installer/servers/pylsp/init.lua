local a = require "nvim-lsp-installer.core.async"
local _ = require "nvim-lsp-installer.core.functional"
local server = require "nvim-lsp-installer.server"
local pip3 = require "nvim-lsp-installer.core.managers.pip3"
local process = require "nvim-lsp-installer.core.process"
local notify = require "nvim-lsp-installer.notify"
local middleware = require "nvim-lsp-installer.middleware"
local spawn = require "nvim-lsp-installer.core.spawn"

return function(name, root_dir)
    middleware.register_server_hook(name, function()
        vim.api.nvim_create_user_command(
            "PylspInstall",
            a.scope(function(opts)
                local plugins = opts.fargs
                local plugins_str = table.concat(plugins, ", ")
                notify(("Installing %s..."):format(plugins_str))
                local result = spawn.pip {
                    "install",
                    "-U",
                    "--disable-pip-version-check",
                    plugins,
                    stdio_sink = process.simple_sink(),
                    with_paths = { pip3.venv_path(root_dir) },
                }
                if vim.in_fast_event() then
                    a.scheduler()
                end
                result
                    :on_success(function()
                        notify(("Successfully installed pylsp plugins %s"):format(plugins_str))
                    end)
                    :on_failure(function()
                        notify("Failed to install requested pylsp plugins.", vim.log.levels.ERROR)
                    end)
            end),
            {
                desc = "[nvim-lsp-installer] Installs the provided packages in the same venv as pylsp.",
                nargs = "+",
                complete = _.always {
                    "pyls-flake8",
                    "pylsp-mypy",
                    "pyls-spyder",
                    "pyls-isort",
                    "python-lsp-black",
                    "pyls-memestra",
                    "pylsp-rope",
                },
            }
        )
    end)

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "python" },
        homepage = "https://github.com/python-lsp/python-lsp-server",
        installer = pip3.packages { "python-lsp-server[all]" },
        default_options = {
            cmd_env = pip3.env(root_dir),
        },
    }
end
