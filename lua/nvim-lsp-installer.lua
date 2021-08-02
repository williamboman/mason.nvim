local M = {}

-- :'<,'>!sort | column -t
local _SERVERS = {
    ["angularls"]               =  require("nvim-lsp-installer.servers.angularls"),
    ["bashls"]                  =  require("nvim-lsp-installer.servers.bashls"),
    ["clangd"]                  =  require("nvim-lsp-installer.servers.clangd"),
    ["clojure_lsp"]             =  require("nvim-lsp-installer.servers.clojure_lsp"),
    ["cmake"]                   =  require("nvim-lsp-installer.servers.cmake"),
    ["cssls"]                   =  require("nvim-lsp-installer.servers.cssls"),
    ["denols"]                  =  require("nvim-lsp-installer.servers.denols"),
    ["dockerls"]                =  require("nvim-lsp-installer.servers.dockerls"),
    ["elixirls"]                =  require("nvim-lsp-installer.servers.elixirls"),
    ["elmls"]                   =  require("nvim-lsp-installer.servers.elmls"),
    ["ember"]                   =  require("nvim-lsp-installer.servers.ember"),
    ["eslintls"]                =  require("nvim-lsp-installer.servers.eslintls"),
    ["fortls"]                  =  require("nvim-lsp-installer.servers.fortls"),
    ["gopls"]                   =  require("nvim-lsp-installer.servers.gopls"),
    ["graphql"]                 =  require("nvim-lsp-installer.servers.graphql"),
    ["hls"]                     =  require("nvim-lsp-installer.servers.hls"),
    ["html"]                    =  require("nvim-lsp-installer.servers.html"),
    ["intelephense"]            =  require("nvim-lsp-installer.servers.intelephense"),
    ["jsonls"]                  =  require("nvim-lsp-installer.servers.jsonls"),
    ["kotlin_language_server"]  =  require("nvim-lsp-installer.servers.kotlin_language_server"),
    ["omnisharp"]               =  require("nvim-lsp-installer.servers.omnisharp"),
    ["purescript"]              =  require("nvim-lsp-installer.servers.purescriptls"),
    ["pyright"]                 =  require("nvim-lsp-installer.servers.pyright"),
    ["rome"]                    =  require("nvim-lsp-installer.servers.rome"),
    ["rust_analyzer"]           =  require("nvim-lsp-installer.servers.rust_analyzer"),
    ["solargraph"]              =  require("nvim-lsp-installer.servers.solargraph"),
    ["sqlls"]                   =  require("nvim-lsp-installer.servers.sqlls"),
    ["sqls"]                    =  require("nvim-lsp-installer.servers.sqls"),
    ["sumneko_lua"]             =  require("nvim-lsp-installer.servers.sumneko_lua"),
    ["svelte"]                  =  require("nvim-lsp-installer.servers.svelte"),
    ["tailwindcss"]             =  require("nvim-lsp-installer.servers.tailwindcss"),
    ["terraformls"]             =  require("nvim-lsp-installer.servers.terraformls"),
    ["texlab"]                  =  require("nvim-lsp-installer.servers.texlab"),
    ["tsserver"]                =  require("nvim-lsp-installer.servers.tsserver"),
    ["vimls"]                   =  require("nvim-lsp-installer.servers.vimls"),
    ["vuels"]                   =  require("nvim-lsp-installer.servers.vuels"),
    ["yamlls"]                  =  require("nvim-lsp-installer.servers.yamlls"),
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

return M
