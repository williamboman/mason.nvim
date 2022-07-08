local a = require "mason-core.async"
local path = require "mason-core.path"
local fetch = require "mason-core.fetch"
local _ = require "mason-core.functional"
local lspconfig_server_mapping = require "mason-lspconfig.mappings.server"
local script_utils = require "mason-scripts.utils"

local MASON_SCHEMAS_DIR = path.concat { vim.loop.cwd(), "lua", "mason-schemas" }

---@async
local function create_lsp_setting_schema_files()
    local lsp_schemas_path = path.concat { MASON_SCHEMAS_DIR, "lsp" }

    for _, file in
        ipairs(vim.fn.glob(
            path.concat {
                lsp_schemas_path,
                "*",
            },
            1,
            1
        ))
    do
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
                script_utils.write_file(
                    path.concat {
                        lsp_schemas_path,
                        ("%s.lua"):format(lspconfig_server_mapping.lspconfig_to_package[server_name]),
                    },
                    "return " .. vim.inspect(schema, { newline = "", indent = "" }),
                    "w"
                )
            end
        end
    end
end

a.run_blocking(function()
    a.wait_all {
        create_lsp_setting_schema_files,
    }
end)
