local fun = require "nvim-lsp-installer.core.functional.function"

local _ = {}

---@param pattern string
---@param str string
_.matches = fun.curryN(function(pattern, str)
    return str:match(pattern) ~= nil
end, 2)

---@param template string
---@param string string
_.format = fun.curryN(function(template, string)
    return template:format(string)
end, 2)

return _
