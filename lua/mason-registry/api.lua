local _ = require "mason-core.functional"
local fetch = require "mason-core.fetch"

local api = {}

-- https://github.com/williamboman/mason-registry-api
local BASE_URL = "https://api.mason-registry.dev"

local stringify_params = _.compose(_.join "&", _.map(_.join "="), _.sort_by(_.head), _.to_pairs)

---@async
---@param path string
---@param opts { params: table<string, any>? }?
---@return Result # JSON decoded response.
function api.get(path, opts)
    if opts and opts.params then
        local params = stringify_params(opts.params)
        path = ("%s?%s"):format(path, params)
    end
    return fetch(("%s%s"):format(BASE_URL, path), {
        headers = {
            Accept = "application/vnd.mason-registry.v1+json; q=1.0, application/json; q=0.8",
        },
    }):map_catching(vim.json.decode)
end

return api
