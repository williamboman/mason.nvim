local TITLE = "mason.nvim"

return function(msg, level)
    level = level or vim.log.levels.INFO
    vim.notify(msg, level, {
        title = TITLE,
    })
end
