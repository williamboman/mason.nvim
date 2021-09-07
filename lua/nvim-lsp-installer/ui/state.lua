local M = {}

function M.create_state_container(initial_state, subscriber)
    -- we do deepcopy to make sure instances of state containers doesn't mutate the initial state
    local state = vim.deepcopy(initial_state)
    local has_unsubscribed = false

    return function(mutate_fn)
        mutate_fn(state)
        if not has_unsubscribed then
            subscriber(state)
        end
    end,
        function()
            return state
        end,
        function(val)
            has_unsubscribed = val
        end
end

return M
