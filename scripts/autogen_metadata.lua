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

for _, file in ipairs(vim.fn.glob(Path.concat { generated_dir, "*" }, 1, 1)) do
    print("Deleting " .. file)
    vim.fn.delete(file)
end

---@param path string
---@param txt string
---@param flag string|number
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

---@param server Server
local function get_supported_filetypes(server)
    local config = require(("lspconfig.server_configurations.%s"):format(server.name))
    local default_options = server:get_default_options()
    local filetypes = coalesce(
        -- nvim-lsp-installer options has precedence
        default_options.filetypes,
        config.default_config.filetypes,
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
    ---@type table<string, Server>
    local language_map = {}

    local available_servers = servers.get_available_servers()
    for _, server in pairs(available_servers) do
        local languages = server.languages
        for _, language in pairs(languages) do
            if not language_map[language] then
                language_map[language] = {}
            end
            table.insert(language_map[language], server)
        end
    end

    local autocomplete_candidates = {}
    for language, language_servers in pairs(language_map) do
        local non_deprecated_servers = vim.tbl_filter(function(server)
            return server.deprecated == nil
        end, language_servers)
        local is_candidate = #non_deprecated_servers > 0

        if #non_deprecated_servers == 1 then
            local server = non_deprecated_servers[1]
            local server_name_similarity_check = server.name:find(language, 1, true) == 1
            if server_name_similarity_check then
                -- There's only one server that supports this language, and it's name is similar enough to the language name.
                is_candidate = false
            end
        end

        if is_candidate then
            autocomplete_candidates[language] = vim.tbl_map(function(server)
                return server.name
            end, non_deprecated_servers)
            table.sort(autocomplete_candidates[language])
        end
    end

    write_file(
        Path.concat { generated_dir, "language_autocomplete_map.lua" },
        "return " .. vim.inspect(autocomplete_candidates),
        "w"
    )
end

do
    local metadata = {}

    ---@param server Server
    local function create_metadata_entry(server)
        return { filetypes = get_supported_filetypes(server) }
    end

    local available_servers = servers.get_available_servers()
    for _, server in pairs(available_servers) do
        metadata[server.name] = create_metadata_entry(server)
    end

    write_file(Path.concat { generated_dir, "metadata.lua" }, "return " .. vim.inspect(metadata), "w")
end
