local notify = require "nvim-lsp-installer.notify"
local dispatcher = require "nvim-lsp-installer.dispatcher"

local M = {}

-- :'<,'>!sort
local _SERVERS = {
    ["angularls"] = require "nvim-lsp-installer.servers.angularls",
    ["ansiblels"] = require "nvim-lsp-installer.servers.ansiblels",
    ["bashls"] = require "nvim-lsp-installer.servers.bashls",
    ["clangd"] = require "nvim-lsp-installer.servers.clangd",
    ["clojure_lsp"] = require "nvim-lsp-installer.servers.clojure_lsp",
    ["cmake"] = require "nvim-lsp-installer.servers.cmake",
    ["cssls"] = require "nvim-lsp-installer.servers.cssls",
    ["denols"] = require "nvim-lsp-installer.servers.denols",
    ["dockerls"] = require "nvim-lsp-installer.servers.dockerls",
    ["efm"] = require "nvim-lsp-installer.servers.efm",
    ["elixirls"] = require "nvim-lsp-installer.servers.elixirls",
    ["elmls"] = require "nvim-lsp-installer.servers.elmls",
    ["ember"] = require "nvim-lsp-installer.servers.ember",
    ["eslintls"] = require "nvim-lsp-installer.servers.eslintls",
    ["fortls"] = require "nvim-lsp-installer.servers.fortls",
    ["gopls"] = require "nvim-lsp-installer.servers.gopls",
    ["graphql"] = require "nvim-lsp-installer.servers.graphql",
    ["groovyls"] = require "nvim-lsp-installer.servers.groovyls",
    ["hls"] = require "nvim-lsp-installer.servers.hls",
    ["html"] = require "nvim-lsp-installer.servers.html",
    ["intelephense"] = require "nvim-lsp-installer.servers.intelephense",
    ["jedi_language_server"] = require "nvim-lsp-installer.servers.jedi_language_server",
    ["jsonls"] = require "nvim-lsp-installer.servers.jsonls",
    ["kotlin_language_server"] = require "nvim-lsp-installer.servers.kotlin_language_server",
    ["omnisharp"] = require "nvim-lsp-installer.servers.omnisharp",
    ["purescriptls"] = require "nvim-lsp-installer.servers.purescriptls",
    ["pylsp"] = require "nvim-lsp-installer.servers.pylsp",
    ["pyright"] = require "nvim-lsp-installer.servers.pyright",
    ["rome"] = require "nvim-lsp-installer.servers.rome",
    ["rust_analyzer"] = require "nvim-lsp-installer.servers.rust_analyzer",
    ["solargraph"] = require "nvim-lsp-installer.servers.solargraph",
    ["sqlls"] = require "nvim-lsp-installer.servers.sqlls",
    ["sqls"] = require "nvim-lsp-installer.servers.sqls",
    ["stylelint_lsp"] = require "nvim-lsp-installer.servers.stylelint_lsp",
    ["sumneko_lua"] = require "nvim-lsp-installer.servers.sumneko_lua",
    ["svelte"] = require "nvim-lsp-installer.servers.svelte",
    ["tailwindcss"] = require "nvim-lsp-installer.servers.tailwindcss",
    ["terraformls"] = require "nvim-lsp-installer.servers.terraformls",
    ["texlab"] = require "nvim-lsp-installer.servers.texlab",
    ["tflint"] = require "nvim-lsp-installer.servers.tflint",
    ["tsserver"] = require "nvim-lsp-installer.servers.tsserver",
    ["vimls"] = require "nvim-lsp-installer.servers.vimls",
    ["vuels"] = require "nvim-lsp-installer.servers.vuels",
    ["yamlls"] = require "nvim-lsp-installer.servers.yamlls",
}

function M.get_server(server_name)
    local server = _SERVERS[server_name]
    if server then
        return true, server
    end
    return false, ("Server %s does not exist."):format(server_name)
end

function M.get_available_servers()
    return vim.tbl_values(_SERVERS)
end

function M.get_installed_servers()
    return vim.tbl_filter(function(server)
        return server:is_installed()
    end, M.get_available_servers())
end

function M.get_uninstalled_servers()
    return vim.tbl_filter(function(server)
        return not server:is_installed()
    end, M.get_available_servers())
end

function M.install(server_name)
    local ok, server = M.get_server(server_name)
    if not ok then
        return notify(("Unable to find LSP server %s.\n\n%s"):format(server_name, server), vim.log.levels.ERROR)
    end
    local success, error = pcall(server.install, server)
    if not success then
        pcall(server.uninstall, server)
        return notify(("Failed to install %s.\n\n%s"):format(server_name, vim.inspect(error)), vim.log.levels.ERROR)
    end
end

function M.uninstall(server_name)
    local ok, server = M.get_server(server_name)
    if not ok then
        return notify(("Unable to find LSP server %s.\n\n%s"):format(server_name, server), vim.log.levels.ERROR)
    end
    local success, error = pcall(server.uninstall, server)
    if not success then
        notify(("Unable to uninstall %s.\n\n%s"):format(server_name, vim.inspect(error)), vim.log.levels.ERROR)
        return success
    end
    notify(("Successfully uninstalled %s."):format(server_name))
end

function M.register(server)
    _SERVERS[server.name] = server
end

function M.on_server_ready(cb)
    dispatcher.register_server_ready_callback(cb)
    for _, server in pairs(M.get_installed_servers()) do
        dispatcher.dispatch_server_ready(server)
    end
end

-- "Proxy" function for triggering attachment of LSP servers to all buffers (useful when just installed a new server
-- that wasn't installed at launch)
function M.lsp_attach_proxy()
    -- As of writing, if the lspconfig server provides a filetypes setting, it uses FileType as trigger, otherwise it uses BufReadPost
    local cur_bufnr = vim.fn.bufnr "%"
    vim.cmd [[ bufdo do FileType | do BufReadPost ]]
    vim.cmd(("buffer %s"):format(cur_bufnr)) -- restore buffer
end

return M
