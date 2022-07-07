local a = require "mason.core.async"
local Path = require "mason.core.path"
local fetch = require "mason.core.fetch"
local _ = require "mason.core.functional"
local fs = require "mason.core.fs"
local lspconfig_server_mapping = require "mason-lspconfig.server-mapping"

local generated_dir = Path.concat { vim.fn.getcwd(), "lua", "mason", "_generated" }
local schemas_dir = Path.concat { generated_dir, "lsp-schemas" }

print("Creating directory " .. generated_dir)
vim.fn.mkdir(generated_dir, "p")

print("Creating directory " .. schemas_dir)
vim.fn.mkdir(schemas_dir, "p")

---@async
---@param path string
---@param contents string
---@param flags string
local function write_file(path, contents, flags)
    fs.async.write_file(
        path,
        table.concat({
            "-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.",
            "-- stylua: ignore start",
            contents,
        }, "\n"),
        flags
    )
end

local function get_lspconfig(name)
    return require(("lspconfig.server_configurations.%s"):format(name))
end

---@async
local function create_lspconfig_filetype_map()
    local filetype_map = {}

    for _, server_name in ipairs(_.keys(lspconfig_server_mapping.lspconfig_to_package)) do
        local config = get_lspconfig(server_name)
        for _, filetype in ipairs(config.default_config.filetypes or {}) do
            if not filetype_map[filetype] then
                filetype_map[filetype] = {}
            end
            table.insert(filetype_map[filetype], server_name)
            table.sort(filetype_map[filetype])
        end
    end

    write_file(Path.concat { generated_dir, "lspconfig_filetype_map.lua" }, "return " .. vim.inspect(filetype_map), "w")
end
---@async
local function create_lsp_setting_schema_files()
    for _, file in ipairs(vim.fn.glob(Path.concat { schemas_dir, "*" }, 1, 1)) do
        print("Deleting " .. file)
        vim.fn.delete(file)
    end

    local gist_data = fetch(
        "https://gist.githubusercontent.com/williamboman/a01c3ce1884d4b57cc93422e7eae7702/raw/lsp-packages.json"
    ):get_or_throw()
    local package_json_mappings = vim.json.decode(gist_data)

    for _, server_name in ipairs(_.keys(lspconfig_server_mapping.lspconfig_to_package)) do
        local package_json_url = package_json_mappings[server_name]
        if package_json_url then
            print(("Fetching %q..."):format(package_json_url))
            local response = fetch(package_json_url):get_or_throw()
            local schema = vim.json.decode(response)
            if schema.contributes and schema.contributes.configuration then
                schema = schema.contributes.configuration
            end
            if not schema.properties then
                -- Some servers (like dartls) seem to provide an array of configurations (for more than just LSP stuff)
                print(("Could not find appropriate schema structure for %s."):format(server_name))
            else
                write_file(
                    Path.concat {
                        schemas_dir,
                        ("%s.lua"):format(lspconfig_server_mapping.lspconfig_to_package[server_name]),
                    },
                    "return " .. vim.inspect(schema, { newline = "", indent = "" }),
                    "w"
                )
            end
        end
    end
end

---@async
local function create_package_index()
    a.scheduler()
    local packages = {}
    local to_lua_path = _.compose(_.gsub("/", "."), _.gsub("^lua/", ""))
    for _, package_path in ipairs(vim.fn.glob("lua/mason/packages/*/init.lua", false, true)) do
        local package_filename = vim.fn.fnamemodify(package_path, ":h:t")
        local lua_path = to_lua_path(vim.fn.fnamemodify(package_path, ":h"))
        local pkg = require(lua_path)
        assert(package_filename == pkg.name, ("Package name is not the same as its module name %s"):format(lua_path))
        packages[pkg.name] = lua_path
    end

    write_file(Path.concat { generated_dir, "package_index.lua" }, "return " .. vim.inspect(packages), "w")
end

a.run_blocking(function()
    a.wait_all(_.filter(_.identity, {
        create_lspconfig_filetype_map, -- TODO is this needed?
        not vim.env.SKIP_SCHEMAS and create_lsp_setting_schema_files,
        create_package_index,
    }))
end)
