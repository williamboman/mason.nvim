local _ = require "mason-core.functional"
local fetch = require "mason-core.fetch"

local api = {}

-- https://github.com/williamboman/mason-registry-api
local BASE_URL = "https://api.mason-registry.dev"

local stringify_params = _.compose(_.join "&", _.map(_.join "="), _.sort_by(_.head), _.to_pairs)

---@alias ApiFetchOpts { params: table<string, any>? }

---@async
---@param path string
---@param opts ApiFetchOpts?
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

---@alias ApiSignature<T> fun(path_params: T, opts?: ApiFetchOpts): Result

---@param path_template string
local function get(path_template)
    ---@param path_params table
    ---@param opts ApiFetchOpts?
    return function(path_params, opts)
        local path = path_template:gsub("{([%w_%.0-9]+)}", function(prop)
            return path_params[prop]
        end)
        -- This is done so that test stubs trigger as expected (you have to explicitly match against nil arguments)
        if opts then
            return api.get(path, opts)
        else
            return api.get(path)
        end
    end
end

api.repo = {
    releases = {
        ---@type ApiSignature<{ repo: string }>
        latest = get "/api/repo/{repo}/releases/latest",
        ---@type ApiSignature<{ repo: string }>
        all = get "/api/repo/{repo}/releases/all",
    },
    tags = {
        ---@type ApiSignature<{ repo: string }>
        latest = get "/api/repo/{repo}/tags/latest",
        ---@type ApiSignature<{ repo: string }>
        all = get "/api/repo/{repo}/tags/all",
    },
}

api.npm = {
    versions = {
        ---@type ApiSignature<{ package: string }>
        latest = get "/api/npm/{package}/versions/latest",
        ---@type ApiSignature<{ package: string }>
        all = get "/api/npm/{package}/versions/all",
    },
}

api.pypi = {
    versions = {
        ---@type ApiSignature<{ package: string }>
        latest = get "/api/pypi/{package}/versions/latest",
        ---@type ApiSignature<{ package: string }>
        all = get "/api/pypi/{package}/versions/all",
    },
}

api.rubygems = {
    versions = {
        ---@type ApiSignature<{ gem: string }>
        latest = get "/api/rubygems/{gem}/versions/latest",
        ---@type ApiSignature<{ gem: string }>
        all = get "/api/rubygemspypi/{gem}/versions/all",
    },
}

return api
