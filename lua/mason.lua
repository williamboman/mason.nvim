local settings = require "mason.settings"
local path = require "mason.core.path"
local platform = require "mason.core.platform"

local M = {}

---@param config MasonSettings | nil
function M.setup(config)
    if config then
        settings.set(config)
    end

    vim.env.PATH = path.bin_prefix() .. platform.path_sep .. vim.env.PATH

    require "mason.command-api"
end

---@param pkg_path string
local function lazy_require(pkg_path)
    return setmetatable({}, {
        __index = function(_, k)
            return require(pkg_path)[k]
        end,
        __call = function(_, ...)
            return require(pkg_path)(...)
        end,
    })
end

return M
