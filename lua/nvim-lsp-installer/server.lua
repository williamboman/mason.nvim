local fs = require("nvim-lsp-installer.fs")
local path = require("nvim-lsp-installer.path")

local M = {}

-- :'<,'>!sort
local _SERVERS = {
    "angularls",
    "bashls",
    "clangd",
    "clojure_lsp",
    "cmake",
    "cssls",
    "denols",
    "dockerls",
    "elixirls",
    "elmls",
    "eslintls",
    "gopls",
    "graphql",
    "html",
    "jsonls",
    "omnisharp",
    "pyright",
    "rust_analyzer",
    "solargraph",
    "sumneko_lua",
    "texlab",
    "tsserver",
    "vimls",
    "vuels",
    "yamlls",
}

local function get_servers(server_names)
    local result = {}
    for _, server_name in pairs(server_names) do
        local ok, server = M.get_server(server_name)
        if ok then
            result[server_name] = server
        else
            vim.api.nvim_err_writeln(("Unable to find LSP server %s. Error=%s"):format(server_name, server))
        end
    end
    return result
end

function M.get_server(server_name)
    return pcall(require, ("nvim-lsp-installer.servers.%s"):format(server_name))
end

function M.get_available_servers()
    return vim.tbl_values(get_servers(_SERVERS))
end

function M.get_installed_servers()
    return vim.tbl_filter(
        function (server)
            return server:is_installed()
        end,
        M.get_available_servers()
    )
end

function M.get_uninstalled_servers()
    return vim.tbl_filter(
        function (server)
            return not server:is_installed()
        end,
        M.get_available_servers()
    )
end

function M.install(server_name)
    local ok, server = M.get_server(server_name)
    if not ok then
        return vim.api.nvim_err_writeln(("Unable to find LSP server %s. Error=%s"):format(server_name, server))
    end
    local success, error = pcall(server.install, server)
    if not success then
        pcall(server.uninstall, server)
        return vim.api.nvim_err_writeln(("Failed to install %s. Error=%s"):format(server_name, vim.inspect(error)))
    end
end

function M.uninstall(server_name)
    local ok, server = M.get_server(server_name)
    if not ok then
        return vim.api.nvim_err_writeln(("Unable to find LSP server %s. Error=%s"):format(server_name, server))
    end
    local success, error = pcall(server.uninstall, server)
    if not success then
        vim.api.nvim_err_writeln(("Unable to uninstall %s. Error=%s"):format(server_name, vim.inspect(error)))
        return success
    end
    print(("Successfully uninstalled %s"):format(server_name))
end

function M.get_server_root_path(server)
    return path.concat { vim.fn.stdpath("data"), "lsp_servers", server }
end

M.Server = {}
M.Server.__index = M.Server

---@class Server
--@param opts table
-- @field name (string)                  The name of the LSP server. This MUST correspond with lspconfig's naming.
--
-- @field root_dir (string)              The root directory of the installation. Most servers will make use of server.get_server_root_path() to produce its root_dir path.
--
-- @field installer (function)           The function that installs the LSP (see the .installers module). The function signature should be `function (server, callback)`, where
--                                       `server` is the Server instance being installed, and `callback` is a function that must be called upon completion. The `callback` function
--                                       has the signature `function (success, result)`, where `success` is a boolean and `result` is of any type (similar to `pcall`).
--
-- @field default_options (table)        The default options to be passed to lspconfig's .setup() function. Each server should provide at least the `cmd` field.
--
-- @field pre_install_check (function)   An optional function to be executed before the installer. This allows ensuring that any prerequisites are fulfilled.
--                                       This could for example be verifying that required build tools are installed.
function M.Server:new(opts)
    return setmetatable({
        name = opts.name,
        _installer = opts.installer,
        _root_dir = opts.root_dir,
        _default_options = opts.default_options,
        _pre_install_check = opts.pre_install_check,
    }, M.Server)
end

function M.Server:setup(opts)
    -- We require the lspconfig server here in order to do it as late as possible.
    -- The reason for this is because once a lspconfig server has been imported, it's
    -- automatically registered with lspconfig and causes it to show up in :LspInfo and whatnot.
    require("lspconfig")[self.name].setup(
        vim.tbl_deep_extend("force", self._default_options, opts)
    )
end

function M.Server:get_default_options()
    return vim.deepcopy(self._default_options)
end

function M.Server:is_installed()
    return fs.dir_exists(self._root_dir)
end

function M.Server:create_root_dir()
    fs.mkdirp(self._root_dir)
end

function M.Server:install()
    if self._pre_install_check then
        self._pre_install_check()
    end

    -- We run uninstall after pre_install_check because we don't want to
    -- unnecessarily uninstall a server should it no longer pass the
    -- pre_install_check.
    self:uninstall()

    self:create_root_dir()

    self._installer(self, function (success, result)
        if not success then
            vim.api.nvim_err_writeln(("Server installation failed for %s. %s"):format(self.name, result))
            pcall(self.uninstall, self)
        else
            print(("Successfully installed %s"):format(self.name))
        end
    end)
end

function M.Server:uninstall()
    fs.rmrf(self._root_dir)
end

return M
