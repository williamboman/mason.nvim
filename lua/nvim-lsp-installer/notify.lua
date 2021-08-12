local TITLE = "nvim-lsp-installer"

return function(msg, level)
    local has_notify_plugin, notify = pcall(require, "notify")
    level = level or vim.log.levels.INFO
    if has_notify_plugin then
        notify(msg, level, {
            title = TITLE,
        })
    else
        vim.notify(("[%s] %s"):format(TITLE, msg), level)
    end
end
