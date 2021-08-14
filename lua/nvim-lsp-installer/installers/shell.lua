local M = {}

local default_opts = {
    prefix = "set -euo pipefail;",
}

function M.raw(raw_script, opts)
    opts = opts or {}
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

        if type(opts.env) == "table" and vim.tbl_count(opts.env) then
            -- passing an empty Lua table causes E475, for whatever reason
            jobstart_opts.env = opts.env
        end

        local shell = vim.o.shell
        vim.o.shell = "/bin/bash"
        vim.cmd [[new]]
        vim.fn.termopen((opts.prefix or default_opts.prefix) .. raw_script, jobstart_opts)
        vim.o.shell = shell
        vim.cmd [[startinsert]]
    end
end

return M
