local settings = require "mason.settings"
local path = require "mason-core.path"
local platform = require "mason-core.platform"

local M = {}

---@param config MasonSettings?
function M.setup(config)
    if config then
        settings.set(config)
    end

    if settings.current.PATH == "prepend" then
        vim.env.PATH = path.bin_prefix() .. platform.path_sep .. vim.env.PATH
    elseif settings.current.PATH == "append" then
        vim.env.PATH = vim.env.PATH .. platform.path_sep .. path.bin_prefix()
    end

    require "mason.ui.colors"
    require "mason.api.command"
end

return M
