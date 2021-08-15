local TITLE = "nvim-lsp-installer"

return function(msg, level)
    local has_notify_plugin = pcall(require, "notify")
    level = level or vim.log.levels.INFO
    if has_notify_plugin then
        vim.notify(msg, level, {
            title = TITLE,
        })
    else
        vim.notify(("[%s] %s"):format(TITLE, msg), level)
    end
end
