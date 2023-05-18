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
        return string.sub(package.config, 1, 1)
    end
end)()

local M = {}

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

---@param dir string?
function M.install_prefix(dir)
    local settings = require "mason.settings"
    return M.concat { settings.current.install_root_dir, dir }
end

---@param executable string?
function M.bin_prefix(executable)
    return M.concat { M.install_prefix "bin", executable }
end

---@param file string?
function M.share_prefix(file)
    return M.concat { M.install_prefix "share", file }
end

---@param file string?
function M.opt_prefix(file)
    return M.concat { M.install_prefix "opt", file }
end

---@param name string?
function M.package_prefix(name)
    return M.concat { M.install_prefix "packages", name }
end

---@param name string?
function M.package_build_prefix(name)
    return M.concat { M.install_prefix "staging", name }
end

---@param name string
function M.package_lock(name)
    return M.package_build_prefix(("%s.lock"):format(name))
end

function M.registry_prefix()
    return M.install_prefix "registries"
end

return M
