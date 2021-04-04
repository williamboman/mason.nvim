local installer = require('nvim-lsp-installer.installer')
local capabilities = require('nvim-lsp-installer.capabilities')

local root_dir = installer.get_server_root_path('tsserver')

return installer.create_lsp_config_installer {
    name = "tsserver",
    root_dir = root_dir,
    install_cmd = [[npm install typescript-language-server]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/typescript-language-server', '--stdio' },
        capabilities = capabilities.create(),
    },
    extras = {
        rename_file = function(old, new)
            local old_uri = vim.uri_from_fname(old)
            local new_uri = vim.uri_from_fname(new)

            -- TODO: send only to tsserver
            for _, client in pairs(vim.lsp.get_active_clients()) do
                client.request(
                    'workspace/executeCommand',
                    {
                        command = '_typescript.applyRenameFile',
                        arguments = {
                            {
                                sourceUri = old_uri,
                                targetUri = new_uri,
                            },
                        },
                    }
                )
            end
        end,
        organize_imports = function(bufname)
            bufname = bufname or vim.api.nvim_buf_get_name(0)

            -- TODO: send only to tsserver
            for _, client in pairs(vim.lsp.get_active_clients()) do
                client.request(
                    'workspace/executeCommand',
                    {
                        command = '_typescript.organizeImports',
                        arguments = {bufname},
                    }
                )
            end
        end,
    }
}
