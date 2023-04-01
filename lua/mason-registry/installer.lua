local a = require "mason-core.async"
local OneShotChannel = require("mason-core.async.control").OneShotChannel
local Result = require "mason-core.result"
local sources = require "mason-registry.sources"

local M = {}

---@type OneShotChannel?
local update_channel

---@async
function M.run()
    if not update_channel or update_channel:is_closed() then
        update_channel = OneShotChannel.new()
        a.run(function()
            update_channel:send(Result.try(function(try)
                local updated_sources = {}
                for source in sources.iter { include_uninstalled = true } do
                    source:get_installer():if_present(function(installer)
                        try(installer():map_err(function(err)
                            return ("%s failed to install: %s"):format(source, err)
                        end))
                        table.insert(updated_sources, source)
                    end)
                end
                return updated_sources
            end):on_success(function(updated_sources)
                if #updated_sources > 0 then
                    require("mason-registry"):emit("update", updated_sources)
                end
            end))
        end, function() end)
    end

    return update_channel:receive()
end

return M
