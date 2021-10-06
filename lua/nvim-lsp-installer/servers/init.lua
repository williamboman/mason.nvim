local Data = require "nvim-lsp-installer.data"
local path = require "nvim-lsp-installer.path"
local fs = require "nvim-lsp-installer.fs"
local settings = require "nvim-lsp-installer.settings"

local M = {}

local function vscode_langservers_extracted(name)
    return settings.current.allow_federated_servers and "vscode-langservers-extracted"
        or "vscode-langservers-extracted_" .. name
end

-- By default the install dir will be the same as the server's name.
-- There are two cases when servers should install to a different location:
--  1. federated server installations, (see :help nvim-lsp-installer-settings)
--  2. legacy reasons, where some servers were previously installed to a location different than their name
local INSTALL_DIRS = {
    ["bashls"] = "bash",
    ["cssls"] = vscode_langservers_extracted "cssls",
    ["dockerls"] = "dockerfile",
    ["elixirls"] = "elixir",
    ["elmls"] = "elm",
    ["eslintls"] = "eslint",
    ["gopls"] = "go",
    ["hls"] = "haskell",
    ["html"] = vscode_langservers_extracted "html",
    ["intelephense"] = "php",
    ["jsonls"] = vscode_langservers_extracted "jsonls",
    ["kotlin_language_server"] = "kotlin",
    ["purescriptls"] = "purescript",
    ["pyright"] = "python",
    ["rust_analyzer"] = "rust",
    ["tailwindcss"] = "tailwindcss_npm",
    ["terraformls"] = "terraform",
    ["texlab"] = "latex",
    ["vimls"] = "vim",
    ["yamlls"] = "yaml",
}

-- :'<,'>!sort
local CORE_SERVERS = Data.set_of {
    "angularls",
    "ansiblels",
    "bashls",
    "bicep",
    "clangd",
    "clojure_lsp",
    "cmake",
    "cssls",
    "denols",
    "diagnosticls",
    "dockerls",
    "dotls",
    "efm",
    "elixirls",
    "elmls",
    "ember",
    "emmet_ls",
    "eslintls",
    "fortls",
    "gopls",
    "graphql",
    "groovyls",
    "hls",
    "html",
    "intelephense",
    "jdtls",
    "jedi_language_server",
    "jsonls",
    "kotlin_language_server",
    "lemminx",
    "ltex",
    "ocamlls",
    "omnisharp",
    "prismals",
    "puppet",
    "purescriptls",
    "pylsp",
    "pyright",
    "rescriptls",
    "rome",
    "rust_analyzer",
    "serve_d",
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
    "volar",
    "vuels",
    "yamlls",
    "zls",
}

local INITIALIZED_SERVERS = {}

local cached_server_roots

local function scan_server_roots()
    if cached_server_roots then
        return cached_server_roots
    end
    local result = {}
    local ok, entries = pcall(fs.readdir, path.SERVERS_ROOT_DIR)
    if not ok then
        -- presume servers root dir has not been created yet (i.e., no servers installed)
        return {}
    end
    for i = 1, #entries do
        local entry = entries[i]
        if entry.type == "directory" then
            result[#result + 1] = entry.name
        end
    end
    cached_server_roots = Data.set_of(result)
    vim.schedule(function()
        cached_server_roots = nil
    end)
    return cached_server_roots
end

local function get_server_install_dir(server_name)
    return INSTALL_DIRS[server_name] or server_name
end

function M.get_server_install_path(dirname)
    return path.concat { path.SERVERS_ROOT_DIR, dirname }
end

function M.is_server_installed(server_name)
    local scanned_server_dirs = scan_server_roots()
    local dirname = get_server_install_dir(server_name)
    return scanned_server_dirs[dirname] or false
end

-- returns a tuple of [server_name, requested_version], where requested_version may be nil
function M.parse_server_tuple(server_name)
    return vim.split(server_name, "@")
end

function M.get_server(server_name)
    if INITIALIZED_SERVERS[server_name] then
        return true, INITIALIZED_SERVERS[server_name]
    end

    if not CORE_SERVERS[server_name] then
        return false, ("Server %s does not exist."):format(server_name)
    end

    local ok, server_factory = pcall(require, ("nvim-lsp-installer.servers.%s"):format(server_name))
    if ok then
        INITIALIZED_SERVERS[server_name] = server_factory(
            server_name,
            M.get_server_install_path(get_server_install_dir(server_name))
        )
        return true, INITIALIZED_SERVERS[server_name]
    end
    return false,
        (
            "Unable to import server %s.\n\nThis is an unexpected error, please file an issue at %s with the following information:\n%s"
        ):format(server_name, "https://github.com/williamboman/nvim-lsp-installer", server_factory)
end

local function get_available_server_names()
    return vim.tbl_keys(vim.tbl_extend("force", CORE_SERVERS, INITIALIZED_SERVERS))
end

local function resolve_servers(server_names)
    return Data.list_map(function(server_name)
        local ok, server = M.get_server(server_name)
        if not ok then
            error(server)
        end
        return server
    end, server_names)
end

function M.get_available_servers()
    return resolve_servers(get_available_server_names())
end

function M.get_installed_servers()
    return resolve_servers(vim.tbl_filter(function(server_name)
        return M.is_server_installed(server_name)
    end, get_available_server_names()))
end

function M.get_uninstalled_servers()
    return resolve_servers(vim.tbl_filter(function(server_name)
        return not M.is_server_installed(server_name)
    end, get_available_server_names()))
end

function M.register(server)
    INSTALL_DIRS[server.name] = vim.fn.fnamemodify(server.root_dir, ":t")
    INITIALIZED_SERVERS[server.name] = server
end

return M
