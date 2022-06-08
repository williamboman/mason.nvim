local _ = require "nvim-lsp-installer.core.functional"
local path = require "nvim-lsp-installer.core.path"
local fs = require "nvim-lsp-installer.core.fs"
local settings = require "nvim-lsp-installer.settings"
local log = require "nvim-lsp-installer.log"

local M = {}

-- By default the install dir will be the same as the server's name.
-- There are two cases when servers should install to a different location:
--  1. Legacy reasons, where some servers were previously installed to a location different than their name
--  2. There is a breaking change to a server that motivates changing its install dir (e.g. to "bust" existing installations).
local INSTALL_DIRS = {
    ["bashls"] = "bash",
    ["dockerls"] = "dockerfile",
    ["elixirls"] = "elixir",
    ["elmls"] = "elm",
    ["eslint"] = "vscode-eslint",
    ["gopls"] = "go",
    ["hls"] = "haskell",
    ["intelephense"] = "php",
    ["kotlin_language_server"] = "kotlin",
    ["phpactor"] = "phpactor-source",
    ["purescriptls"] = "purescript",
    ["pyright"] = "python",
    ["rust_analyzer"] = "rust",
    ["tailwindcss"] = "tailwindcss_npm",
    ["terraformls"] = "terraform",
    ["texlab"] = "latex",
    ["vimls"] = "vim",
    ["yamlls"] = "yaml",
}

local CORE_SERVERS = _.set_of {
    "angularls",
    "ansiblels",
    "apex_ls",
    "arduino_language_server",
    "asm_lsp",
    "astro",
    "awk_ls",
    "bashls",
    "beancount",
    "bicep",
    "bsl_ls",
    "ccls",
    "clangd",
    "clarity_lsp",
    "clojure_lsp",
    "cmake",
    "codeqlls",
    "crystalline",
    "csharp_ls",
    "cssls",
    "cssmodules_ls",
    "cucumber_language_server",
    "dartls",
    "denols",
    "dhall_lsp_server",
    "diagnosticls",
    "dockerls",
    "dotls",
    "efm",
    "elixirls",
    "elmls",
    "ember",
    "emmet_ls",
    "erlangls",
    "esbonio",
    "eslint",
    "flux_lsp",
    "foam_ls",
    "fortls",
    "fsautocomplete",
    "golangci_lint_ls",
    "gopls",
    "grammarly",
    "graphql",
    "groovyls",
    "haxe_language_server",
    "hls",
    "hoon_ls",
    "html",
    "intelephense",
    "jdtls",
    "jedi_language_server",
    "jsonls",
    "jsonnet_ls",
    "julials",
    "kotlin_language_server",
    "lelwel_ls",
    "lemminx",
    "ltex",
    "marksman",
    "mm0_ls",
    "nickel_ls",
    "nimls",
    "ocamlls",
    "ocamllsp",
    "omnisharp",
    "opencl_ls",
    "perlnavigator",
    "phpactor",
    "powershell_es",
    "prismals",
    "prosemd_lsp",
    "psalm",
    "puppet",
    "purescriptls",
    "pylsp",
    "pyright",
    "quick_lint_js",
    "r_language_server",
    "reason_ls",
    "remark_ls",
    "rescriptls",
    "rnix",
    "robotframework_ls",
    "rome",
    "rust_analyzer",
    "salt_ls",
    "scry",
    "serve_d",
    "slint_lsp",
    "solang",
    "solargraph",
    "solc",
    "solidity_ls",
    "sorbet",
    "sourcekit",
    "sourcery",
    "sqlls",
    "sqls",
    "stylelint_lsp",
    "sumneko_lua",
    "svelte",
    "svlangserver",
    "svls",
    "tailwindcss",
    "taplo",
    "teal_ls",
    "terraformls",
    "texlab",
    "tflint",
    "theme_check",
    "tsserver",
    "vala_ls",
    "verible",
    "vimls",
    "visualforce_ls",
    "vls",
    "volar",
    "vuels",
    "wgsl_analyzer",
    "yamlls",
    "zk",
    "zls",
}

---@type table<string, Server>
local INITIALIZED_SERVERS = {}

local cached_server_roots

local function scan_server_roots()
    if cached_server_roots then
        return cached_server_roots
    end
    log.trace "Scanning server roots"
    ---@type string[]
    local result = {}
    local ok, entries = pcall(fs.sync.readdir, settings.current.install_root_dir)
    if not ok then
        log.debug("Failed to scan server roots", entries)
        -- presume servers root dir has not been created yet (i.e., no servers installed)
        return {}
    end
    for i = 1, #entries do
        local entry = entries[i]
        if entry.type == "directory" then
            result[#result + 1] = entry.name
        end
    end
    cached_server_roots = _.set_of(result)
    vim.schedule(function()
        cached_server_roots = nil
    end)
    log.trace("Resolved server roots", cached_server_roots)
    return cached_server_roots
end

---@param server_name string
---@return string
local function get_server_install_dir(server_name)
    log.fmt_trace("Getting server installation dirname. uses_new_setup=%s", settings.uses_new_setup)
    if settings.uses_new_setup then
        return server_name
    else
        return INSTALL_DIRS[server_name] or server_name
    end
end

function M.get_server_install_path(dirname)
    log.trace("Getting server installation path", settings.current.install_root_dir, dirname)
    return path.concat { settings.current.install_root_dir, dirname }
end

---@param server_name string
function M.is_server_installed(server_name)
    log.trace("Checking if server is installed", server_name)
    local scanned_server_dirs = scan_server_roots()
    local dirname = get_server_install_dir(server_name)
    return scanned_server_dirs[dirname] or false
end

---@param server_identifier string @The server identifier to parse.
---@return string, string|nil @Returns a (server_name, requested_version) tuple, where requested_version may be nil.
function M.parse_server_identifier(server_identifier)
    return unpack(vim.split(server_identifier, "@"))
end

---@param server_name string
---@return boolean, Server
function M.get_server(server_name)
    if INITIALIZED_SERVERS[server_name] then
        return true, INITIALIZED_SERVERS[server_name]
    end

    if not CORE_SERVERS[server_name] then
        return false, ("Server %s does not exist."):format(server_name)
    end

    local ok, server_factory = pcall(require, ("nvim-lsp-installer.servers.%s"):format(server_name))
    if ok then
        log.trace("Initializing core server", server_name)
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

---@type fun(server_names: string): Server[]
local resolve_servers = _.map(function(server_name)
    local ok, server = M.get_server(server_name)
    if not ok then
        error(server)
    end
    return server
end)

---@return string[]
function M.get_available_server_names()
    return vim.tbl_keys(vim.tbl_extend("force", CORE_SERVERS, INITIALIZED_SERVERS))
end

---@return string[]
function M.get_installed_server_names()
    return vim.tbl_filter(function(server_name)
        return M.is_server_installed(server_name)
    end, M.get_available_server_names())
end

---@return string[]
function M.get_uninstalled_server_names()
    return vim.tbl_filter(function(server_name)
        return not M.is_server_installed(server_name)
    end, M.get_available_server_names())
end

-- Expensive to call the first time - loads all server modules.
function M.get_available_servers()
    return resolve_servers(M.get_available_server_names())
end

-- Somewhat expensive to call the first time (depends on how many servers are currently installed).
function M.get_installed_servers()
    return resolve_servers(M.get_installed_server_names())
end

-- Expensive to call the first time (depends on how many servers are currently not installed).
function M.get_uninstalled_servers()
    return resolve_servers(M.get_uninstalled_server_names())
end

---@param server Server @The server to register.
function M.register(server)
    INSTALL_DIRS[server.name] = vim.fn.fnamemodify(server.root_dir, ":t")
    INITIALIZED_SERVERS[server.name] = server
end

return M
