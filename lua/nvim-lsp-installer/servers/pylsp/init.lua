local server = require "nvim-lsp-installer.server"
local pip3 = require "nvim-lsp-installer.installers.pip3"
local process = require "nvim-lsp-installer.process"
local notify = require "nvim-lsp-installer.notify"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "python" },
        homepage = "https://github.com/python-lsp/python-lsp-server",
        installer = pip3.packages { "python-lsp-server[all]" },
        default_options = {
            cmd = { pip3.executable(root_dir, "pylsp") },
            commands = {
                PylspInstall = {
                    function(...)
                        -- `nargs+` requires at least one argument -> no empty table
                        local plugins = { ... }
                        local plugins_str = table.concat(plugins, ", ")
                        notify(("Installing %q..."):format(plugins_str))
                        process.spawn(
                            pip3.executable(root_dir, "pip"),
                            {
                                args = vim.list_extend({ "install", "-U", "--disable-pip-version-check" }, plugins),
                                stdio_sink = process.simple_sink(),
                            },
                            vim.schedule_wrap(function(success)
                                if success then
                                    notify(("Successfully installed %q"):format(plugins_str))
                                else
                                    notify("Failed to install requested plugins.", vim.log.levels.ERROR)
                                end
                            end)
                        )
                    end,
                    description = "Installs the provided packages in the same venv as pylsp.",
                    ["nargs=+"] = true,
                },
            },
        },
    }
end
