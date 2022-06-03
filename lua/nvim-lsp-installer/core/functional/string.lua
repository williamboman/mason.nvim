local fun = require "nvim-lsp-installer.core.functional.function"

local _ = {}

---@param pattern string
---@param str string
_.matches = fun.curryN(function(pattern, str)
    return str:match(pattern) ~= nil
end, 2)

---@param template string
---@param str string
_.format = fun.curryN(function(template, str)
    return template:format(str)
end, 2)

---@param sep string
---@param str string
_.split = fun.curryN(function(sep, str)
    return vim.split(str, sep)
end, 2)

---@param pattern string
---@param repl string|function|table
---@param str string
_.gsub = fun.curryN(function(pattern, repl, str)
    return string.gsub(str, pattern, repl)
end, 3)

return _
