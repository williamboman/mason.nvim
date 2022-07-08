local a = require "mason-core.async"
local path = require "mason-core.path"
local _ = require "mason-core.functional"
local lspconfig_server_mapping = require "mason-lspconfig.mappings.server"
local script_utils = require "mason-scripts.utils"

local MASON_LSPCONFIG_DIR = path.concat { vim.loop.cwd(), "lua", "mason-lspconfig" }

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

    script_utils.write_file(
        path.concat { MASON_LSPCONFIG_DIR, "mappings", "filetype.lua" },
        "return " .. vim.inspect(filetype_map),
        "w"
    )
end

a.run_blocking(function()
    a.wait_all {
        create_lspconfig_filetype_map,
    }
end)
