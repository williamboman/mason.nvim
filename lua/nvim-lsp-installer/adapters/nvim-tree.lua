local M = {}

local tsserverExtras = require("nvim-lsp-installer.extras.tsserver")

function M.connect()
    local ok, events = pcall(require, "nvim-tree.events")
    if not ok then
        return vim.notify("Unable to import nvim-tree module when connecting nvim-lsp-installer adapter.", vim.log.levels.ERROR)
    end

    events.on_node_renamed(function (payload)
        -- TODO: not do this when renaming folders
        tsserverExtras.rename_file(payload.old_name, payload.new_name)
    end)
end

return M
