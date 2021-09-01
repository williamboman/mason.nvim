local installers = require "nvim-lsp-installer.installers"

local M = {}

local function termopen(opts)
    return function(server, callback)
        local jobstart_opts = {
            cwd = server._root_dir,
            on_exit = function(_, exit_code)
                if exit_code ~= 0 then
                    callback(false, ("Exit code %d"):format(exit_code))
                else
                    callback(true, nil)
                end
            end,
        }

        if type(opts.env) == "table" and vim.tbl_count(opts.env) > 0 then
            -- passing an empty Lua table causes E475, for whatever reason
            jobstart_opts.env = opts.env
        end

        local orig_shell = vim.o.shell
        vim.o.shell = opts.shell
        vim.cmd [[new]]
        vim.fn.termopen(opts.cmd, jobstart_opts)
        vim.o.shell = orig_shell
        vim.cmd [[startinsert]] -- so that we tail the term log nicely ¯\_(ツ)_/¯
    end
end

function M.bash(raw_script, opts)
    local default_opts = {
        prefix = "set -euo pipefail;",
        env = {},
    }
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})

    return termopen {
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

    return termopen {
        shell = "cmd.exe",
        cmd = raw_script,
        env = opts.env,
    }
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
