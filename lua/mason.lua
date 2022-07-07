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

return M
