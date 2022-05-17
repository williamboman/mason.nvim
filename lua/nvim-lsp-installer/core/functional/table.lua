local fun = require "nvim-lsp-installer.core.functional.function"

local _ = {}

_.prop = fun.curryN(function(index, tbl)
    return tbl[index]
end, 2)

return _
