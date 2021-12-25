---@class ServerHints
---@field server Server
local ServerHints = {}
ServerHints.__index = ServerHints

function ServerHints.new(server)
    return setmetatable({ server = server }, ServerHints)
end

---@param language string
---@return boolean
function ServerHints:is_language_equal(language)
    local match_start, match_end = self.server.name:find(language, 1, true)
    -- This is somewhat... arbitrary
    return match_start ~= nil
        and (match_end - match_start) >= 2 -- the match need to be at least 2 in length
        -- match needs to start in the beginning - if it's not, then the total string lengths cannot differ too much
        and (match_start == 1 or (match_start < 3 and (math.abs(#self.server.name - #language) < 4)))
end

function ServerHints:get_hints()
    local hints = {}
    if self.server.languages then
        for _, language in ipairs(self.server.languages) do
            if not self:is_language_equal(language) then
                hints[#hints + 1] = language
            end
        end
    end
    return hints
end

function ServerHints:__tostring()
    local hints = self:get_hints()
    if #hints == 0 then
        return ""
    end
    return "(" .. table.concat(hints, ", ") .. ")"
end

return ServerHints
