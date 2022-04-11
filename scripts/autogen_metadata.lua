local uv = vim.loop
local a = require "nvim-lsp-installer.core.async"
local Path = require "nvim-lsp-installer.path"
local fetch = require "nvim-lsp-installer.core.fetch"
local Data = require "nvim-lsp-installer.data"

local coalesce = Data.coalesce

package.loaded["nvim-lsp-installer.servers"] = nil
package.loaded["nvim-lsp-installer.fs"] = nil
local servers = require "nvim-lsp-installer.servers"

local generated_dir = Path.concat { vim.fn.getcwd(), "lua", "nvim-lsp-installer", "_generated" }
local schemas_dir = Path.concat { generated_dir, "schemas" }

print("Creating directory " .. generated_dir)
vim.fn.mkdir(generated_dir, "p")

print("Creating directory " .. schemas_dir)
vim.fn.mkdir(schemas_dir, "p")

for _, file in ipairs(vim.fn.glob(Path.concat { generated_dir, "*" }, 1, 1)) do
    print("Deleting " .. file)
    vim.fn.delete(file)
end

for _, file in ipairs(vim.fn.glob(Path.concat { schemas_dir, "*" }, 1, 1)) do
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

local function get_lspconfig(name)
    return require(("lspconfig.server_configurations.%s"):format(name))
end

---@param server Server
local function get_supported_filetypes(server)
    if server.name == "awk_ls" then
        -- awk_ls only supports 0.7 and returns nothing on lower versions
        return { "awk" }
    end
    local config = get_lspconfig(server.name)
    local default_options = server:get_default_options()
    local filetypes = coalesce(
        -- nvim-lsp-installer options has precedence
        default_options and default_options.filetypes,
        config.default_config.filetypes,
        {}
    )
    return filetypes
end

---@async
local function create_filetype_map()
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

---@async
local function create_autocomplete_map()
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
            is_candidate = not vim.startswith(server.name, language)
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

---@async
local function create_server_metadata()
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

---@async
local function create_setting_schema_files()
    local available_servers = servers.get_available_servers()
    local gist_data = fetch(
        "https://gist.githubusercontent.com/williamboman/a01c3ce1884d4b57cc93422e7eae7702/raw/lsp-packages.json"
    ):get_or_throw()
    local package_json_mappings = vim.json.decode(gist_data)

    for _, server in pairs(available_servers) do
        local package_json_url = package_json_mappings[server.name]
        if package_json_url then
            print(("Fetching %q..."):format(package_json_url))
            local response = fetch(package_json_url):get_or_throw()
            local schema = vim.json.decode(response)
            if schema.contributes and schema.contributes.configuration then
                schema = schema.contributes.configuration
            end
            if not schema.properties then
                -- Some servers (like dartls) seem to provide an array of configurations (for more than just LSP stuff)
                print(("Could not find appropriate schema structure for %s."):format(server.name))
            else
                write_file(
                    Path.concat { schemas_dir, ("%s.lua"):format(server.name) },
                    "return " .. vim.inspect(schema, { newline = "", indent = "" }),
                    "w"
                )
            end
        end
    end
end

a.run_blocking(function()
    create_filetype_map()
    create_autocomplete_map()
    create_server_metadata()
    create_setting_schema_files()
end)
