local lspconfig = require'lspconfig'
local configs = require'lspconfig/configs'

local installer = require'nvim-lsp-installer.installer'

if not lspconfig.eslintls then
    configs.eslintls = {
        default_config = {
            filetypes = {'javascript', 'javascriptreact', 'typescript', 'typescriptreact'},
            root_dir = lspconfig.util.root_pattern(".eslintrc*", "package.json", ".git"),
            settings = {
                nodePath = '', -- If this is a non-null/undefined value the eslint LSP runs into runtime exceptions.
                validate = 'on',
                run = 'onType',
                workingDirectory = {mode = "auto"},
                workspaceFolder = {
                    uri = "/",
                    name = "root",
                },
                codeAction = {
                    disableRuleComment = {
                        enable = true,
                        location = "sameLine",
                    },
                    showDocumentation = {
                        enable = true
                    }
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

local root_dir = installer.get_server_root_path('eslint')
local install_cmd = [[
git clone https://github.com/microsoft/vscode-eslint .;
npm install;
cd server;
npm install;
npx tsc;
]]

return installer.Installer:new {
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
