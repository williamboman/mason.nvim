local installers = require "nvim-lsp-installer.installers"
local process = require "nvim-lsp-installer.process"

local M = {}

---@param opts {shell: string, cmd: string[], env: table|nil}
local function shell(opts)
    ---@type ServerInstallerFunction
    return function(_, callback, context)
        local _, stdio = process.spawn(opts.shell, {
            args = opts.args,
            cwd = context.install_dir,
            stdio_sink = context.stdio_sink,
            env = process.graft_env(opts.env or {}, {
                "PSMODULEPATH", -- https://github.com/williamboman/nvim-lsp-installer/issues/271
            }),
        }, callback)

        if stdio and opts.cmd then
            local stdin = stdio[1]

            stdin:write(opts.cmd)
            stdin:write "\n"
            stdin:close()
        end
    end
end

---@param raw_script string @The bash script to execute as-is.
---@param opts {prefix: string, env: table}
function M.bash(raw_script, opts)
    local default_opts = {
        prefix = "set -euo pipefail;",
        env = {},
    }
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})

    return shell {
        shell = "bash",
        args = { "-c", (opts.prefix or "") .. raw_script },
        env = opts.env,
    }
end

---@param raw_script string @The sh script to execute as-is.
---@param opts {prefix: string, env: table}
function M.sh(raw_script, opts)
    local default_opts = {
        prefix = "set -eu;",
        env = {},
    }
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})

    return shell {
        shell = "sh",
        cmd = (opts.prefix or "") .. raw_script,
        env = opts.env,
    }
end

---@param raw_script string @The cmd.exe script to execute as-is.
---@param opts {env: table}
function M.cmd(raw_script, opts)
    local default_opts = {
        env = {},
    }
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})

    return shell {
        shell = "cmd.exe",
        args = { "/C", raw_script },
        env = opts.env,
    }
end

---@param raw_script string @The powershell script to execute as-is.
---@param opts {prefix: string, env: table}
function M.powershell(raw_script, opts)
    local default_opts = {
        env = {},
        -- YIKES https://stackoverflow.com/a/63301751
        prefix = "$ProgressPreference = 'SilentlyContinue';",
    }
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})

    return shell {
        shell = "powershell.exe",
        args = { "-NoProfile", "-Command", (opts.prefix or "") .. raw_script },
        env = opts.env,
    }
end

---@param raw_script string @A script that is compatible with bash and cmd.exe.
---@param opts {env: table}
function M.polyshell(raw_script, opts)
    local default_opts = {
        env = {},
    }
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})

    return installers.when {
        unix = M.bash(raw_script, { env = opts.env }),
        win = M.cmd(raw_script, { env = opts.env }),
    }
end

return M
