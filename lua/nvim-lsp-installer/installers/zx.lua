local fs = require("nvim-lsp-installer.fs")
local path = require("nvim-lsp-installer.path")

local uv = vim.loop

local M = {}

local INSTALL_DIR = path.concat { vim.fn.stdpath("data"), "lsp_servers", ".zx" }
local ZX_EXECUTABLE = path.concat { INSTALL_DIR, "node_modules", ".bin", "zx" }

local has_installed_zx = false

function M.install_zx(callback, force)
    force = force or false -- be careful with boolean logic if flipping this

    if has_installed_zx and not force then
        callback()
        return
    end

    if vim.fn.executable("npm") ~= 1 or vim.fn.executable("node") ~= 1 then
        error("Cannot install zx because npm and/or node not installed.")
    end

    local is_zx_already_installed = fs.file_exists(ZX_EXECUTABLE)
    local npm_command = is_zx_already_installed and "update" or "install"

    print(("Preparing for :LspInstall, please wait… ($ npm %s zx)"):format(npm_command))

    fs.mkdirp(INSTALL_DIR)

    uv.spawn("npm", {
        args = { npm_command, "zx" },
        cwd = INSTALL_DIR,
    }, vim.schedule_wrap(function (code)
        if code ~= 0 then
            error("Failed to install zx.")
        end
        has_installed_zx = true
        vim.cmd [[ echon "" ]] -- clear the previously printed feedback message… ¯\_(ツ)_/¯
        callback()
    end))
end

function M.file(relpath)
    local script_path = path.realpath(relpath, 3)
    return function (server, callback)
        M.install_zx(function ()
            vim.cmd [[new]]
            vim.fn.termopen(("set -e; %q %q"):format(
                ZX_EXECUTABLE,
                script_path
            ), {
                    cwd = server._root_dir,
                    on_exit = function (_, exit_code)
                        if exit_code ~= 0 then
                            callback(false, ("Exit code was non-successful: %d"):format(exit_code))
                        else
                            callback(true, nil)
                        end
                    end
                })
            vim.cmd [[startinsert]] -- so that the buffer tails the term log nicely
        end, false)
    end
end

return M
