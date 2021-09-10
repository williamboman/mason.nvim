local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"

local M = {}

function M.pipe(installers)
    if #installers == 0 then
        error "No installers to pipe."
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
    return M.pipe(Data.list_reverse(installers))
end

function M.always_succeed(installer)
    return function(server, callback, context)
        installer(server, function()
            callback(true)
        end, context)
    end
end

local function get_by_platform(platform_table)
    if platform.is_unix then
        return platform_table.unix
    elseif platform.is_win then
        return platform_table.win
    else
        return nil
    end
end

-- non-exhaustive
function M.on(platform_table)
    return function(server, callback, context)
        local installer = get_by_platform(platform_table)
        if installer then
            installer(server, callback, context)
        else
            callback(true)
        end
    end
end

-- exhaustive
function M.when(platform_table)
    return function(server, callback, context)
        local installer = get_by_platform(platform_table)
        if installer then
            installer(server, callback, context)
        else
            context.stdio_sink.stderr(
                ("Current operating system is not yet supported for server %q."):format(server.name)
            )
            callback(false)
        end
    end
end

return M
