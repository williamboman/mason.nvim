local InstallLocation = require "mason-core.installer.location"
local settings = require "mason.settings"

local M = {}

local function setup_autocmds()
    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            require("mason-core.terminator").terminate(5000)
        end,
        once = true,
    })
end

M.has_setup = false

---@param config MasonSettings?
function M.setup(config)
    if config then
        settings.set(config)
    end

    InstallLocation.global():set_env { PATH = settings.current.PATH }

    require "mason.api.command"
    setup_autocmds()
    require("mason-registry.sources").set_registries(settings.current.registries)
    M.has_setup = true
end

return M
