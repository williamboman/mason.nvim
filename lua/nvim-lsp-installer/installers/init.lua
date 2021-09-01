local platform = require "nvim-lsp-installer.platform"

local M = {}

function M.compose(installers)
    if #installers == 0 then
        error "No installers to compose."
    end

    return function(server, callback)
        local function execute(idx)
            installers[idx](server, function(success, result)
                if not success then
                    -- oh no, error. exit early
                    callback(success, result)
                elseif installers[idx - 1] then
                    -- iterate
                    execute(idx - 1)
                else
                    -- we done
                    callback(success, result)
                end
            end)
        end

        execute(#installers)
    end
end

function M.when(platform_table)
    return function(server, callback)
        if platform.is_unix() then
            if platform_table.unix then
                platform_table.unix(server, callback)
            else
                callback(false, ("Unix is not yet supported for server %q."):format(server.name))
            end
        elseif platform.is_win() then
            if platform_table.win then
                platform_table.win(server, callback)
            else
                callback(false, ("Windows is not yet supported for server %q."):format(server.name))
            end
        else
            callback(false, "installers.when: Could not find installer for current platform.")
        end
    end
end

return M
