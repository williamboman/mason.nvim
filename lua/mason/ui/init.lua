local settings = require "mason.settings"
local M = {}

function M.open()
    local api = require "mason.ui.instance"
    api.window.open {
        border = settings.current.ui.border,
    }
end

function M.set_view(view)
    local api = require "mason.ui.instance"
    api.set_view(view)
end

return M
