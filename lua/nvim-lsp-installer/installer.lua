local M = {}

local _INSTALLERS = {
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

local function get_server_installer(server)
    return pcall(require, 'nvim-lsp-installer.installers.' .. server)
end

function M.get_available_servers() return _INSTALLERS end

function M.get_installed_servers()
    local installed_servers = {}
    for _, server in pairs(M.get_available_servers()) do
        local ok, module = get_server_installer(server)
        if not ok then
            vim.api.nvim_err_writeln("Unable to find installer for " .. server)
            goto continue
        end
        if module:is_installed() then
            table.insert(installed_servers, module)
        end
        ::continue::
    end
    return installed_servers
end

function M.get_uninstalled_servers()
    local installed_servers = M.get_installed_servers()
    return vim.tbl_filter(
        function (server)
            return not vim.tbl_contains(installed_servers, server)
        end,
        M.get_available_servers()
    )
end

function M.install(server)
    local ok, installer = get_server_installer(server)
    if not ok then
        return vim.api.nvim_err_writeln("Unable to find installer for " .. server)
    end
    local success, error = pcall(installer.install, installer)
    if not success then
        pcall(installer.uninstall, installer)
        return vim.api.nvim_err_writeln("Failed to install " .. server .. ". Error=" .. vim.inspect(error))
    end
end

function M.uninstall(server)
    local ok, installer = get_server_installer(server)
    if not ok then
        return vim.api.nvim_err_writeln("Unable to find installer for " .. server)
    end
    local success, error = pcall(installer.uninstall, installer)
    if not success then
        vim.api.nvim_err_writeln('Unable to uninstall ' .. server .. '. Error=' .. vim.inspect(error))
        return success
    end
    print("Successfully uninstalled " .. server)
end

function M.get_server_root_path(server)
    return vim.fn.stdpath('data') .. "/lsp_servers/" .. server
end

M.Installer = {}
M.Installer.__index = M.Installer

---@class Installer
function M.Installer:new(opts)
    return setmetatable({
        name = opts.name,
        _install_cmd = opts.install_cmd,
        _root_dir = opts.root_dir,
        _default_options = opts.default_options,
        _pre_install = opts.pre_install,
    }, M.Installer)
end

function M.Installer:setup(opts)
    -- We require the lspconfig server here in order to do it as late as possible.
    -- The reason for this is because once a lspconfig server has been imported, it's
    -- automatically registered with lspconfig and causes it to show up in :LspInfo and whatnot.
    require'lspconfig'[self.name].setup(
        vim.tbl_deep_extend('force', self._default_options, opts)
    )
end

function M.Installer:is_installed()
    return os.execute('test -d ' .. escape_quotes(self._root_dir)) == 0
end

function M.Installer:create_root_dir()
    if os.execute('mkdir -p ' .. escape_quotes(self._root_dir)) ~= 0 then
        error('Could not create LSP server directory ' .. self._root_dir)
    end
end

function M.Installer:install()
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
                    vim.api.nvim_err_writeln("Installer failed for " .. self.name .. ". Exit code: " .. exit_code)
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

function M.Installer:uninstall()
    -- giggity
    if os.execute('rm -rf ' .. escape_quotes(self._root_dir)) ~= 0 then
        error('Could not remove LSP server directory ' .. self._root_dir)
    end

end

return M
