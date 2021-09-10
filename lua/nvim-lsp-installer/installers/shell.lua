local installers = require "nvim-lsp-installer.installers"
local process = require "nvim-lsp-installer.process"

local M = {}

local function shell(opts)
    return function(server, callback, context)
        local _, stdio = process.spawn(opts.shell, {
            cwd = server.root_dir,
            stdio_sink = context.stdio_sink,
            env = process.graft_env(opts.env or {}),
        }, callback)

        if stdio then
            local stdin = stdio[1]

            stdin:write(opts.cmd)
            stdin:write "\n"
            stdin:close()
        end
    end
end

function M.bash(raw_script, opts)
    local default_opts = {
        prefix = "set -euo pipefail;",
        env = {},
    }
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})

    return shell {
        shell = "/bin/bash",
        cmd = (opts.prefix or "") .. raw_script,
        env = opts.env,
    }
end

function M.remote_bash(url, opts)
    return M.bash(("wget -nv -O - %q | bash"):format(url), opts)
end

function M.cmd(raw_script, opts)
    local default_opts = {
        env = {},
    }
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})

    return shell {
        shell = "cmd.exe",
        cmd = raw_script,
        env = opts.env,
    }
end

function M.powershell(raw_script, opts)
    local default_opts = {
        env = {},
        -- YIKES https://stackoverflow.com/a/63301751
        prefix = "$ProgressPreference = 'SilentlyContinue';",
    }
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})

    return shell {
        shell = "powershell.exe",
        cmd = (opts.prefix or "") .. raw_script,
        env = opts.env,
    }
end

function M.remote_powershell(url, opts)
    return M.powershell(("iwr %q -useb | iex"):format(url), opts)
end

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
