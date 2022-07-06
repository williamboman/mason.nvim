local path = require "mason.core.path"

---@param install_dir string
---@param use_mono boolean
local function generate_cmd(install_dir, use_mono)
    if use_mono then
        return {
            "mono",
            path.concat { install_dir, "omnisharp-mono", "OmniSharp.exe" },
            "--languageserver",
            "--hostPID",
            tostring(vim.fn.getpid()),
        }
    else
        return {
            "dotnet",
            path.concat { install_dir, "omnisharp", "OmniSharp.dll" },
            "--languageserver",
            "--hostPID",
            tostring(vim.fn.getpid()),
        }
    end
end

---@param install_dir string
return function(install_dir)
    return {
        on_new_config = function(config)
            config.cmd = generate_cmd(install_dir, config.use_mono)
        end,
    }
end
