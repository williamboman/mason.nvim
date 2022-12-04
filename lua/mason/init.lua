local settings = require "mason.settings"
local path = require "mason-core.path"
local platform = require "mason-core.platform"

local M = {}

local function setup_autocmds()
    -- lazily set up terminator
    vim.api.nvim_create_autocmd("User", {
        pattern = "__MasonPackageHandle", -- private autocmd specific for this very use case
        callback = function()
            require("mason.terminator").setup()
        end,
        once = true,
    })

    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            require("mason.terminator").terminate()
        end,
        once = true,
    })
end

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

    require "mason.api.command"
    setup_autocmds()
end

return M
