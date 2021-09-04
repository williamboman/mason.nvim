local notify = require "nvim-lsp-installer.notify"
local dispatcher = require "nvim-lsp-installer.dispatcher"

local M = {}

function Set(list)
    local set = {}
    for _, l in ipairs(list) do
        set[l] = true
    end
    return set
end

-- :'<,'>!sort
local CORE_SERVERS = Set {
    "angularls",
    "ansiblels",
    "bashls",
    "clangd",
    "clojure_lsp",
    "cmake",
    "cssls",
    "denols",
    "diagnosticls",
    "dockerls",
    "efm",
    "elixirls",
    "elmls",
    "ember",
    "eslintls",
    "fortls",
    "gopls",
    "graphql",
    "groovyls",
    "hls",
    "html",
    "intelephense",
    "jedi_language_server",
    "jsonls",
    "kotlin_language_server",
    "omnisharp",
    "purescriptls",
    "pylsp",
    "pyright",
    "rescriptls",
    "rome",
    "rust_analyzer",
    "solargraph",
    "sqlls",
    "sqls",
    "stylelint_lsp",
    "sumneko_lua",
    "svelte",
    "tailwindcss",
    "terraformls",
    "texlab",
    "tflint",
    "tsserver",
    "vimls",
    "vuels",
    "yamlls",
}

local CUSTOM_SERVERS_MAP = {}

function M.get_server(server_name)
    -- Registered custom servers have precedence
    if CUSTOM_SERVERS_MAP[server_name] then
        return true, CUSTOM_SERVERS_MAP[server_name]
    end

    if not CORE_SERVERS[server_name] then
        return false, ("Server %s does not exist."):format(server_name)
    end

    local ok, server = pcall(require, ("nvim-lsp-installer.servers.%s"):format(server_name))
    if ok then
        return true, server
    end
    return false,
        (
            "Unable to import server %s.\n\nThis is an unexpected error, please file an issue at %s with the following information:\n%s"
        ):format(server_name, "https://github.com/williamboman/nvim-lsp-installer", server)
end

function M.get_available_servers()
    return vim.tbl_map(function(server_name)
        local ok, server = M.get_server(server_name)
        if not ok then
            error(server)
        end
        return server
    end, vim.tbl_keys(
        vim.tbl_extend("force", CORE_SERVERS, CUSTOM_SERVERS_MAP)
    ))
end

function M.get_installed_servers()
    return vim.tbl_filter(function(server)
        return server:is_installed()
    end, M.get_available_servers())
end

function M.get_uninstalled_servers()
    return vim.tbl_filter(function(server)
        return not server:is_installed()
    end, M.get_available_servers())
end

function M.install(server_name)
    local ok, server = M.get_server(server_name)
    if not ok then
        return notify(("Unable to find LSP server %s.\n\n%s"):format(server_name, server), vim.log.levels.ERROR)
    end
    local success, error = pcall(server.install, server)
    if not success then
        pcall(server.uninstall, server)
        return notify(("Failed to install %s.\n\n%s"):format(server_name, vim.inspect(error)), vim.log.levels.ERROR)
    end
end

function M.uninstall(server_name)
    local ok, server = M.get_server(server_name)
    if not ok then
        return notify(("Unable to find LSP server %s.\n\n%s"):format(server_name, server), vim.log.levels.ERROR)
    end
    local success, error = pcall(server.uninstall, server)
    if not success then
        notify(("Unable to uninstall %s.\n\n%s"):format(server_name, vim.inspect(error)), vim.log.levels.ERROR)
        return success
    end
    notify(("Successfully uninstalled %s."):format(server_name))
end

function M.register(server)
    CUSTOM_SERVERS_MAP[server.name] = server
end

function M.on_server_ready(cb)
    dispatcher.register_server_ready_callback(cb)
    vim.schedule(function()
        for _, server in pairs(M.get_installed_servers()) do
            dispatcher.dispatch_server_ready(server)
        end
    end)
end

-- "Proxy" function for triggering attachment of LSP servers to all buffers (useful when just installed a new server
-- that wasn't installed at launch)
local queued = false
function M.lsp_attach_proxy()
    if queued then
        return
    end
    queued = true
    vim.schedule(function()
        -- As of writing, if the lspconfig server provides a filetypes setting, it uses FileType as trigger, otherwise it uses BufReadPost
        vim.cmd [[ doautoall FileType | doautoall BufReadPost ]]
        queued = false
    end)
end

return M
