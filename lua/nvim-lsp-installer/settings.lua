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
    },

    -- Controls to which degree logs are written to the log file. For example, it's useful to set this to
    -- vim.log.levels.TRACE when debugging issues with server installations.
    log_level = vim.log.levels.WARN,

    -- Whether to allow LSP servers to share the same installation directory.
    -- For some servers, this effectively causes more than one server to be
    -- installed (and uninstalled) when executing `:LspInstall` and
    -- `:LspUninstall`.

    -- For example, installing `cssls` will also install both `jsonls` and `html`
    -- (and the other ways around), as these all share the same underlying
    -- package.
    allow_federated_servers = true,
}

local M = {}

function M.set(opts)
    M.current = vim.tbl_deep_extend("force", DEFAULT_SETTINGS, opts)
end

M.current = DEFAULT_SETTINGS

return M
