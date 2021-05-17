local M = {}

function M.raw(raw_script)
    return function (server, on_exit)
        local shell = vim.o.shell
        vim.o.shell = "/bin/bash"
        vim.cmd [[new]]
        vim.fn.termopen(
            "set -e;\n" .. raw_script,
            {
                cwd = server._root_dir,
                on_exit = on_exit
            }
        )
        vim.o.shell = shell
        vim.cmd([[startinsert]]) -- so that the buffer tails the term log nicely
    end
end

return M
