local notify = require "nvim-lsp-installer.notify"
local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local shell = require "nvim-lsp-installer.installers.shell"

local ConfirmExecutionResult = {
    deny = 1,
    confirmationPending = 2,
    confirmationCanceled = 3,
    approved = 4,
}

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = shell.polyshell [[ git clone --depth 1 https://github.com/microsoft/vscode-eslint . && npm install && npm run compile:server ]],
        pre_setup = function()
            local lspconfig = require "lspconfig"
            local configs = require "lspconfig/configs"

            if not configs.eslintls then
                configs.eslintls = {
                    default_config = {
                        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
                        root_dir = lspconfig.util.root_pattern(".eslintrc*", "package.json", ".git"),
                        -- Refer to https://github.com/Microsoft/vscode-eslint#settings-options for documentation.
                        settings = {
                            validate = "on",
                            run = "onType",
                            codeAction = {
                                disableRuleComment = {
                                    enable = true,
                                    -- "sameLine" might not work as expected, see https://github.com/williamboman/nvim-lsp-installer/issues/4
                                    location = "separateLine",
                                },
                                showDocumentation = {
                                    enable = true,
                                },
                            },
                            rulesCustomizations = {},
                            -- Automatically determine working directory by locating .eslintrc config files.
                            --
                            -- It's recommended not to change this.
                            workingDirectory = { mode = "auto" },
                            -- If nodePath is a non-null/undefined value the eslint LSP runs into runtime exceptions.
                            --
                            -- It's recommended not to change this.
                            nodePath = "",
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
        end,
        default_options = {
            cmd = { "node", path.concat { root_dir, "server", "out", "eslintServer.js" }, "--stdio" },
            handlers = {
                ["eslint/openDoc"] = function(_, _, open_doc)
                    os.execute(string.format("open %q", open_doc.url))
                    return { id = nil, result = true }
                end,
                ["eslint/confirmESLintExecution"] = function()
                    -- VSCode language servers have a policy to request explicit approval
                    -- before applying code changes. We just approve it immediately.
                    return ConfirmExecutionResult.approved
                end,
                ["eslint/probeFailed"] = function()
                    notify("ESLint probe failed.", vim.log.levels.ERROR)
                    return { id = nil, result = true }
                end,
                ["eslint/noLibrary"] = function()
                    notify("Unable to find ESLint library.", vim.log.levels.ERROR)
                    return { id = nil, result = true }
                end,
                ["eslint/noConfig"] = function()
                    notify("Unable to find ESLint configuration.", vim.log.levels.ERROR)
                    return { id = nil, result = true }
                end,
            },
        },
    }
end
