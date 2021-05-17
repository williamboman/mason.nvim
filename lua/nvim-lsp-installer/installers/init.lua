local M = {}

function M.compose(installers)
    if #installers == 0 then
        error("No installers to compose.")
    end

    return function (server, callback)
        local function execute(idx)
            installers[idx](server, function (success, result)
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

return M
