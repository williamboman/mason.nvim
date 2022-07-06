local settings = require "mason.settings"
local M = {}

M.open = function()
    local window = require "mason.ui.instance"
    window.open {
        border = settings.current.ui.border,
    }
end

return M
