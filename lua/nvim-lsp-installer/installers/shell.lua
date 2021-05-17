local M = {}

function M.raw(raw_script)
    return function (server, callback)
        local shell = vim.o.shell
        vim.o.shell = "/bin/bash"
        vim.cmd [[new]]
        vim.fn.termopen(
            "set -e;\n" .. raw_script,
            {
                cwd = server._root_dir,
                on_exit = function (_, exit_code)
                    if exit_code ~= 0 then
                        callback(false, ("Exit code was non-successful: %d"):format(exit_code))
                    else
                        callback(true, nil)
                    end
                end
            }
        )
        vim.o.shell = shell
        vim.cmd([[startinsert]]) -- so that the buffer tails the term log nicely
    end
end

return M
