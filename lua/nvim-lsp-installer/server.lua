local M = {}

-- :'<,'>!sort
local _SERVERS = {
    'bashls',
    'cssls',
    'dockerls',
    'eslintls',
    'graphql',
    'html',
    'jsonls',
    'solargraph',
    'sumneko_lua',
    'tsserver',
    'vimls',
    'yamlls',
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
function M.Server:new(opts)
    return setmetatable({
        name = opts.name,
        _install_cmd = opts.install_cmd,
        _root_dir = opts.root_dir,
        _default_options = opts.default_options,
        _pre_install = opts.pre_install,
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
    if self._pre_install then
        self._pre_install()
    end

    -- We run uninstall after pre_install because we don't want to
    -- unnecessarily uninstall a server should it no longer pass the
    -- pre_install check.
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
                    self:uninstall()
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
