local M = {}

local _INSTALLERS = {
    'vim-ls',
    'graphql-ls',
    'lua-ls',
    'typescript-ls',
    'css-ls',
    'html-ls',
    'json-ls',
    'yaml-ls',
    'bash-ls',
    'docker-ls',
    'ruby-ls',
    'eslint-ls',
}

local function escape_quotes(str)
    return string.format("%q", str)
end

function M.get_server_installer(server)
    return require('nvim-lsp-installer.installers.' .. server)
end

function M.get_available_servers() return _INSTALLERS end

function M.get_installed_servers()
    local installed_servers = {}
    for _, server in ipairs(M.get_available_servers()) do
        local module = M.get_server_installer(server)
        if os.execute('test -d ' .. escape_quotes(module.root_dir)) == 0 then
            table.insert(installed_servers, server)
        end
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

local function _uninstall(server)
    local installer = M.get_server_installer(server)

    -- giggity
    if os.execute('rm -rf ' .. escape_quotes(installer.root_dir)) ~= 0 then
        error('Could not remove LSP server directory ' .. installer.root_dir)
    end
end

local function _install(server)
    local installer = M.get_server_installer(server)

    if installer.pre_install then
        installer.pre_install()
    end

    -- We run uninstall after pre_install because we don't want to
    -- unnecessarily uninstall a server should it no longer pass the
    -- pre_install check.
    _uninstall(server)

    if os.execute('mkdir -p ' .. escape_quotes(installer.root_dir)) ~= 0 then
        error('Could not create LSP server directory ' .. installer.root_dir)
    end

    local shell = vim.o.shell
    vim.o.shell = '/bin/bash'
    vim.cmd [[new]]
    vim.fn.termopen(
        'set -e;\n' .. installer.install_cmd,
        {
            cwd = installer.root_dir,
            on_exit = function (_, exit_code)
                if exit_code ~= 0 then
                    vim.api.nvim_err_writeln("Installer failed for " .. server .. ". Exit code: " .. exit_code)
                    _uninstall(server)
                else
                    print("Successfully installed " .. server)
                end

            end
        }
    )
    vim.o.shell = shell
    vim.cmd([[startinsert]]) -- so that the buffer tails the term log nicely
end

function M.install(server)
    local success, error = pcall(_install, server)
    if not success then
        pcall(_uninstall, server)
        vim.api.nvim_err_writeln("Failed to install " .. server .. ". Error=" .. vim.inspect(error))
    end
    return success
end

function M.uninstall(server)
    local success, error = pcall(_uninstall, server)
    if not success then
        vim.api.nvim_err_writeln('Unable to uninstall ' .. server .. '. Error=' .. vim.inspect(error))
        return success
    end
    print("Successfully uninstalled " .. server)
    return success
end

function M.get_server_root_path(server)
    return vim.fn.stdpath('data') .. "/lsp_servers/" .. server
end

function M.create_lsp_config_installer(module)
    return {
        install_cmd = module.install_cmd,
        root_dir = module.root_dir,
        pre_install = module.pre_install,
        setup = function(opts)
            require'lspconfig'[module.name].setup(
                vim.tbl_deep_extend('force', module.default_options, opts)
            )
        end,
        extras = module.extras or {},
    }
end

return M
