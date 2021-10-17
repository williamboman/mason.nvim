local path = require "nvim-lsp-installer.path"

local DEFAULT_SETTINGS = {
    ui = {
        icons = {
            -- The list icon to use for installed servers.
            server_installed = "◍",
            -- The list icon to use for servers that are pending installation.
            server_pending = "◍",
            -- The list icon to use for servers that are not installed.
            server_uninstalled = "◍",
        },
        keymaps = {
            -- Keymap to expand a server in the UI
            toggle_server_expand = "<CR>",
            -- Keymap to install a server
            install_server = "i",
            -- Keymap to reinstall/update a server
            update_server = "u",
            -- Keymap to uninstall a server
            uninstall_server = "X",
        },
    },

    -- The directory in which to install all servers.
    install_root_dir = path.concat { vim.fn.stdpath "data", "lsp_servers" },

    pip = {
        -- These args will be added to `pip install` calls. Note that setting extra args might impact intended behavior
        -- and is not recommended.
        --
        -- Example: { "--proxy", "https://proxyserver" }
        install_args = {},
    },

    -- Controls to which degree logs are written to the log file. It's useful to set this to vim.log.levels.DEBUG when
    -- debugging issues with server installations.
    log_level = vim.log.levels.INFO,

    -- Whether to allow LSP servers to share the same installation directory. For some servers, this effectively causes
    -- more than one server to be installed (and uninstalled) when executing `:LspInstall` and `:LspUninstall`. For
    -- example, installing `cssls` will also install both `jsonls` and `html` (and the other ways around), as these all
    -- share the same underlying package.
    allow_federated_servers = true,

    -- Limit for the maximum amount of servers to be installed at the same time. Once this limit is reached, any further
    -- servers that are requested to be installed will be put in a queue.
    max_concurrent_installers = 4,
}

local M = {}

M.current = DEFAULT_SETTINGS

function M.set(opts)
    M.current = vim.tbl_deep_extend("force", M.current, opts)
end

return M
