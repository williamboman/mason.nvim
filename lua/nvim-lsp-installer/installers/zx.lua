local fs = require "nvim-lsp-installer.fs"
local path = require "nvim-lsp-installer.path"
local notify = require "nvim-lsp-installer.notify"
local installers = require "nvim-lsp-installer.installers"
local platform = require "nvim-lsp-installer.platform"
local shell = require "nvim-lsp-installer.installers.shell"
local npm = require "nvim-lsp-installer.installers.npm"

local uv = vim.loop

local M = {}

local INSTALL_DIR = path.concat { vim.fn.stdpath "data", "lsp_servers", ".zx" }
local ZX_EXECUTABLE = npm.executable(INSTALL_DIR, "zx")

local has_installed_zx = false

local function zx_installer(force)
    force = force or false -- be careful with boolean logic if flipping this

    return function(_, callback)
        if has_installed_zx and not force then
            callback(true, "zx already installed")
            return
        end

        if vim.fn.executable "npm" ~= 1 or vim.fn.executable "node" ~= 1 then
            callback(false, "Cannot install zx because npm and/or node not installed.")
            return
        end

        local is_zx_already_installed = fs.file_exists(ZX_EXECUTABLE)
        local npm_command = is_zx_already_installed and "update" or "install"

        if not is_zx_already_installed then
            notify(("Preparing for :LspInstall… ($ npm %s zx)"):format(npm_command))
        end

        fs.mkdirp(INSTALL_DIR)

        local handle, pid = uv.spawn(
            platform.is_win() and "npm.cmd" or "npm",
            {
                args = { npm_command, "zx@1" },
                cwd = INSTALL_DIR,
            },
            vim.schedule_wrap(function(code)
                if code ~= 0 then
                    callback(false, "Failed to install zx.")
                    return
                end
                has_installed_zx = true
                vim.cmd [[ echon "" ]] -- clear the previously printed feedback message… ¯\_(ツ)_/¯
                callback(true, nil)
            end)
        )

        if handle == nil then
            callback(false, ("Failed to install/update zx. %s"):format(pid))
        end
    end
end

function M.file(relpath)
    local script_path = path.realpath(relpath, 3)
    return installers.compose {
        shell.polyshell(("%q %q"):format(ZX_EXECUTABLE, ("file:///%s"):format(script_path))),
        zx_installer(false),
    }
end

return M
