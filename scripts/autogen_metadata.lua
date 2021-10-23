local uv = vim.loop
local Path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"

local coalesce = Data.coalesce

package.loaded["nvim-lsp-installer.servers"] = nil
package.loaded["nvim-lsp-installer.fs"] = nil
local servers = require "nvim-lsp-installer.servers"

local generated_dir = Path.concat { vim.fn.getcwd(), "lua", "nvim-lsp-installer", "_generated" }

print("Creating directory " .. generated_dir)
vim.fn.mkdir(generated_dir, "p")

for _, file in ipairs(vim.fn.glob(generated_dir .. "*", 1, 1)) do
    print("Deleting " .. file)
    vim.fn.delete(file)
end

local function write_file(path, txt, flag)
    uv.fs_open(path, flag, 438, function(open_err, fd)
        assert(not open_err, open_err)
        uv.fs_write(
            fd,
            table.concat({
                "-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.",
                "-- stylua: ignore start",
                txt,
            }, "\n"),
            -1,
            function(write_err)
                assert(not write_err, write_err)
                uv.fs_close(fd, function(close_err)
                    assert(not close_err, close_err)
                end)
            end
        )
    end)
end

local function get_supported_filetypes(server)
    local configs = require "lspconfig/configs"
    local lspconfig_server_ok = pcall(require, ("lspconfig/" .. server.name))
    if not lspconfig_server_ok then
        -- This is expected behavior for servers that does not exist in lspconfig.
        print(("Unable to import lspconfig/%s, continuing..."):format(server.name))
    end
    local default_options = server:get_default_options()
    local filetypes = coalesce(
        -- nvim-lsp-installer options has precedence
        default_options.filetypes,
        lspconfig_server_ok and configs[server.name].document_config.default_config.filetypes,
        {}
    )
    return filetypes
end

do
    local filetype_map = {}

    local available_servers = servers.get_available_servers()
    for _, server in pairs(available_servers) do
        for _, filetype in pairs(get_supported_filetypes(server)) do
            if not filetype_map[filetype] then
                filetype_map[filetype] = {}
            end
            table.insert(filetype_map[filetype], server.name)
            table.sort(filetype_map[filetype])
        end
    end

    write_file(Path.concat { generated_dir, "filetype_map.lua" }, "return " .. vim.inspect(filetype_map), "w")
end

do
    local metadata = {}

    local function create_metadata_entry(server)
        return { filetypes = get_supported_filetypes(server) }
    end

    local available_servers = servers.get_available_servers()
    for _, server in pairs(available_servers) do
        metadata[server.name] = create_metadata_entry(server)
    end

    write_file(Path.concat { generated_dir, "metadata.lua" }, "return " .. vim.inspect(metadata), "w")
end
