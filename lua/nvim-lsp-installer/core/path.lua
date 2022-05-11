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

---@path root_path string
---@path path string
function M.is_subdirectory(root_path, path)
    return root_path == path or path:sub(1, #root_path + 1) == root_path .. sep
end

return M
