local uv = vim.loop

local sep = (function()
    ---@diagnostic disable-next-line: undefined-global
    if jit then
        ---@diagnostic disable-next-line: undefined-global
        local os = string.lower(jit.os)
        if os == "linux" or os == "osx" or os == "bsd" then
            return "/"
        else
            return "\\"
        end
    else
        return package.config:sub(1, 1)
    end
end)()

local M = {}

function M.cwd()
    return uv.fs_realpath "."
end

---@param path_components string[]
---@return string
function M.concat(path_components)
    return table.concat(path_components, sep)
end

-- @param relpath string The relative path to get the realpath(1) to.
-- @param depth number The depth in the call stack to introspect. This effectively controls which stack frame should be used when producing the realpath.
--                     The file of the elected stack frame will be used as the "starting point" for the provided relpath.
--
-- @return The realpath (absolute path). Note that this will currently produce results such as /Users/zuck/./script.js which may not be compatible with some tools.
function M.realpath(relpath, depth)
    local callsite_abs_path = debug.getinfo(depth or 2, "S").source:sub(2)
    local normalized_relpath = relpath:gsub("./", "")
    return M.concat { vim.fn.fnamemodify(callsite_abs_path, ":h"), normalized_relpath }
end

function M.is_subdirectory(root_path, path)
    return path:sub(1, #root_path) == root_path
end

return M
