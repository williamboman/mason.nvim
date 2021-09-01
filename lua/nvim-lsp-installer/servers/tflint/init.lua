local server = require "nvim-lsp-installer.server"
local notify = require "nvim-lsp-installer.notify"
local path = require "nvim-lsp-installer.path"
local installers = require "nvim-lsp-installer.installers"
local shell = require "nvim-lsp-installer.installers.shell"

local root_dir = server.get_server_root_path "tflint"

local bin_path = path.concat { root_dir, "tflint" }

return server.Server:new {
    name = "tflint",
    root_dir = root_dir,
    installer = installers.when {
        unix = shell.remote_bash("https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh", {
            env = {
                TFLINT_INSTALL_PATH = root_dir,
                TFLINT_INSTALL_NO_ROOT = 1,
            },
        }),
    },
    default_options = {
        cmd = { bin_path, "--langserver" },
    },
    post_setup = function()
        function _G.lsp_installer_tflint_init()
            notify "Installing TFLint plugins…"
            vim.fn.termopen(("%q --init"):format(bin_path), {
                cwd = path.cwd(),
                on_exit = function(_, exit_code)
                    if exit_code ~= 0 then
                        notify(("Failed to install TFLint (exit code %)."):format(exit_code))
                    else
                        notify "Successfully installed TFLint plugins."
                    end
                end,
            })
            vim.cmd [[startinsert]] -- so that we tail the term log nicely ¯\_(ツ)_/¯
        end

        vim.cmd [[ command! TFLintInit call v:lua.lsp_installer_tflint_init() ]]
    end,
}
