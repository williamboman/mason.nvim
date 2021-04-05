local lspconfig = require'lspconfig'
local configs = require'lspconfig/configs'

local server = require'nvim-lsp-installer.server'

if not lspconfig.eslintls then
    configs.eslintls = {
        default_config = {
            filetypes = {'javascript', 'javascriptreact', 'typescript', 'typescriptreact'},
            root_dir = lspconfig.util.root_pattern(".eslintrc*", "package.json", ".git"),

            -- Refer to https://github.com/Microsoft/vscode-eslint#settings-options for documentation.
            settings = {
                validate = 'on',
                run = 'onType',

                codeAction = {
                    disableRuleComment = {
                        enable = true,
                        -- "sameLine" might not work as expected, see https://github.com/williamboman/nvim-lsp-installer/issues/4
                        location = "separateLine",
                    },
                    showDocumentation = {
                        enable = true
                    }
                },

                -- Automatically determine working directory by locating .eslintrc config files.
                --
                -- It's recommended not to change this.
                workingDirectory = {mode = "auto"},

                -- If nodePath is a non-null/undefined value the eslint LSP runs into runtime exceptions.
                --
                -- It's recommended not to change this.
                nodePath = '',

                -- The "workspaceFolder" is a VSCode concept. We set it to the root
                -- directory to not restrict the LPS server when it traverses the
                -- file tree when locating a .eslintrc config file.
                --
                -- It's recommended not to change this.
                workspaceFolder = {
                    uri = "/",
                    name = "root",
                },
            },
        },
    }
end

local ConfirmExecutionResult = {
    deny = 1,
    confirmationPending = 2,
    confirmationCanceled = 3,
    approved = 4
}

local root_dir = server.get_server_root_path('eslint')
local install_cmd = [[
git clone https://github.com/microsoft/vscode-eslint .;
npm install;
cd server;
npm install;
npx tsc;
]]

return server.Server:new {
    name = "eslintls",
    root_dir = root_dir,
    install_cmd = install_cmd,
    default_options = {
        cmd = {'node', root_dir .. '/server/out/eslintServer.js', '--stdio'},
        handlers = {
            ["eslint/openDoc"] = function (_, _, open_doc)
                os.execute(string.format("open %q", open_doc.url))
                return {id = nil, result = true}
            end,
            ["eslint/confirmESLintExecution"] = function ()
                -- VSCode language servers have a policy to request explicit approval
                -- before applying code changes. We just approve it immediately.
                return ConfirmExecutionResult.approved
            end,
            ["eslint/probeFailed"] = function ()
                vim.api.nvim_err_writeln('ESLint probe failed.')
                return {id = nil, result = true}
            end,
            ["eslint/noLibrary"] = function ()
                vim.api.nvim_err_writeln('Unable to find ESLint library.')
                return {id = nil, result = true}
            end,
            ["eslint/noConfig"] = function ()
                vim.api.nvim_err_writeln('Unable to find ESLint configuration.')
                return {id = nil, result = true}
            end,
        },
    },
}
