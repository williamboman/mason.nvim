local TITLE = "nvim-lsp-installer"

return function(msg, level)
    level = level or vim.log.levels.INFO
    vim.notify(("%s: %s"):format(TITLE, msg), level, {
        title = TITLE,
    })
end
