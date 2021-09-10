local Data = require "nvim-lsp-installer.data"

local M = {}

-- :'<,'>!sort
local CORE_SERVERS = Data.set_of {
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
    "ocamlls",
    "omnisharp",
    "prismals",
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
    return Data.list_map(function(server_name)
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

function M.register(server)
    CUSTOM_SERVERS_MAP[server.name] = server
end

return M
