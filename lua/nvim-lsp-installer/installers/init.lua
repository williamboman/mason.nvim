local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"

local M = {}

function M.join(installers)
    if #installers == 0 then
        error "No installers to join."
    end

    return function(server, callback, context)
        local function execute(idx)
            installers[idx](server, function(success)
                if not success then
                    -- oh no, error. exit early
                    callback(success)
                elseif installers[idx + 1] then
                    -- iterate
                    execute(idx + 1)
                else
                    -- we done
                    callback(success)
                end
            end, context)
        end

        execute(1)
    end
end

-- much fp, very wow
function M.compose(installers)
    return M.join(Data.list_reverse(installers))
end

function M.when(platform_table)
    return function(server, callback, context)
        if platform.is_unix() then
            if platform_table.unix then
                platform_table.unix(server, callback, context)
            else
                context.stdio_sink.stderr(("Unix is not yet supported for server %q."):format(server.name))
                callback(false)
            end
        elseif platform.is_win() then
            if platform_table.win then
                platform_table.win(server, callback, context)
            else
                context.stdio_sink.stderr(("Windows is not yet supported for server %q."):format(server.name))
                callback(false)
            end
        else
            context.sdtio_sink.stderr "installers.when: Could not find installer for current platform."
            callback(false)
        end
    end
end

return M
