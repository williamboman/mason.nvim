local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local installer = require "mason-core.installer"
local log = require "mason-core.log"
local platform = require "mason-core.platform"
local path = require "mason-core.path"

local M = {}

---@async
function M.init()
    log.debug "npm: init"
    local ctx = installer.context()
    return Result.try(function(try)
        try(ctx.spawn.npm {
            "init",
            "--yes",
            "--scope=mason",
        })

        -- Use global-style. The reasons for this are:
        --   a) To avoid polluting the executables (aka bin-links) that npm creates.
        --   b) The installation is, after all, more similar to a "global" installation. We don't really gain
        --      any of the benefits of not using global style (e.g., deduping the dependency tree).
        --
        --  We write to .npmrc manually instead of going through npm because managing a local .npmrc file
        --  is a bit unreliable across npm versions (especially <7), so we take extra measures to avoid
        --  inadvertently polluting global npm config.
        try(Result.pcall(function()
            ctx.fs:append_file(".npmrc", "global-style=true")
        end))

        ctx.stdio_sink.stdout "Initialized npm root\n"
    end)
end

---@async
---@param pkg string
---@param version string
---@param opts? { extra_packages?: string[] }
function M.install(pkg, version, opts)
    opts = opts or {}
    log.fmt_debug("npm: install %s %s %s", pkg, version, opts)
    local ctx = installer.context()
    return ctx.spawn.npm {
        "install",
        ("%s@%s"):format(pkg, version),
        opts.extra_packages or vim.NIL,
    }
end

---@param exec string
function M.bin_path(exec)
    return Result.pcall(platform.when, {
        unix = function()
            return path.concat { "node_modules", ".bin", exec }
        end,
        win = function()
            return path.concat { "node_modules", ".bin", ("%s.cmd"):format(exec) }
        end,
    })
end

return M
