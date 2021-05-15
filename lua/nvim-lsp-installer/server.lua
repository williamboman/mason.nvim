local M = {}

-- :'<,'>!sort
local _SERVERS = {
    "bashls",
    "clangd",
    "cssls",
    "denols",
    "dockerls",
    "eslintls",
    "gopls",
    "graphql",
    "html",
    "jsonls",
    "solargraph",
    "sumneko_lua",
    "texlab",
    "tsserver",
    "vimls",
    "vuels",
    "yamlls",
}

local function escape_quotes(str)
    return string.format("%q", str)
end

local function get_server(server_name)
    return pcall(require, 'nvim-lsp-installer.servers.' .. server_name)
end

local function get_servers(server_names)
    local result = {}
    for _, server_name in pairs(server_names) do
        local ok, server = get_server(server_name)
        if not ok then
            vim.api.nvim_err_writeln("Unable to find LSP server " .. server_name)
            goto continue
        end
        result[server_name] = server
        ::continue::
    end
    return result
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
    local ok, server = get_server(server_name)
    if not ok then
        return vim.api.nvim_err_writeln("Unable to find LSP server " .. server_name)
    end
    local success, error = pcall(server.install, server)
    if not success then
        pcall(server.uninstall, server)
        return vim.api.nvim_err_writeln("Failed to install " .. server_name .. ". Error=" .. vim.inspect(error))
    end
end

function M.uninstall(server_name)
    local ok, server = get_server(server_name)
    if not ok then
        return vim.api.nvim_err_writeln("Unable to find LSP server " .. server_name)
    end
    local success, error = pcall(server.uninstall, server)
    if not success then
        vim.api.nvim_err_writeln('Unable to uninstall ' .. server_name .. '. Error=' .. vim.inspect(error))
        return success
    end
    print("Successfully uninstalled " .. server_name)
end

function M.get_server_root_path(server)
    return vim.fn.stdpath('data') .. "/lsp_servers/" .. server
end

M.Server = {}
M.Server.__index = M.Server

---@class Server
--@param opts table
-- @field name (string)                  The name of the LSP server. This MUST correspond with lspconfig's naming.
--
-- @field root_dir (string)              The root directory of the installation. Most servers will make use of server.get_server_root_path() to produce its root_dir path.
--
-- @field install_cmd (string)           The shell script that installs the LSP. Make sure to exit with an error code (e.g. exit 1) on failures.
--                                       The shell script is executed with "set -e" (exits the script on first non-successful command) by default.
--
-- @field default_options (table)        The default options to be passed to lspconfig's .setup() function. Each server should provide at least the `cmd` field.
--
-- @field pre_install_check (function)   An optional function to be executed before the install_cmd. This allows ensuring that any prerequisites are fulfilled.
--                                       This could for example be verifying that required build tools are installed.
function M.Server:new(opts)
    return setmetatable({
        name = opts.name,
        _install_cmd = opts.install_cmd,
        _root_dir = opts.root_dir,
        _default_options = opts.default_options,
        _pre_install_check = opts.pre_install_check,
    }, M.Server)
end

function M.Server:setup(opts)
    -- We require the lspconfig server here in order to do it as late as possible.
    -- The reason for this is because once a lspconfig server has been imported, it's
    -- automatically registered with lspconfig and causes it to show up in :LspInfo and whatnot.
    require'lspconfig'[self.name].setup(
        vim.tbl_deep_extend('force', self._default_options, opts)
    )
end

function M.Server:is_installed()
    return os.execute('test -d ' .. escape_quotes(self._root_dir)) == 0
end

function M.Server:create_root_dir()
    if os.execute('mkdir -p ' .. escape_quotes(self._root_dir)) ~= 0 then
        error('Could not create LSP server directory ' .. self._root_dir)
    end
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

    local shell = vim.o.shell
    vim.o.shell = '/bin/bash'
    vim.cmd [[new]]
    vim.fn.termopen(
        'set -e;\n' .. self._install_cmd,
        {
            cwd = self._root_dir,
            on_exit = function (_, exit_code)
                if exit_code ~= 0 then
                    vim.api.nvim_err_writeln("Server installation failed for " .. self.name .. ". Exit code: " .. exit_code)
                    pcall(self.uninstall, self)
                else
                    print("Successfully installed " .. self.name)
                end

            end
        }
    )
    vim.o.shell = shell
    vim.cmd([[startinsert]]) -- so that the buffer tails the term log nicely
end

function M.Server:uninstall()
    -- giggity
    if os.execute('rm -rf ' .. escape_quotes(self._root_dir)) ~= 0 then
        error('Could not remove LSP server directory ' .. self._root_dir)
    end

end

return M
