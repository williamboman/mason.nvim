local fs = require "nvim-lsp-installer.fs"
local path = require "nvim-lsp-installer.path"
local installers = require "nvim-lsp-installer.installers"
local platform = require "nvim-lsp-installer.platform"
local npm = require "nvim-lsp-installer.installers.npm"
local process = require "nvim-lsp-installer.process"

local M = {}

local INSTALL_DIR = path.concat { vim.fn.stdpath "data", "lsp_servers", ".zx" }
local ZX_EXECUTABLE = npm.executable(INSTALL_DIR, "zx")

local has_installed_zx = false

local function zx_installer(force)
    force = force or false -- be careful with boolean logic if flipping this

    return function(_, callback, context)
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
            context.stdio_sink.stdout(("Preparing for installation… (npm %s zx)"):format(npm_command))
        end

        fs.mkdirp(INSTALL_DIR)

        -- todo use process installer
        local handle, pid = process.spawn(platform.is_win and "npm.cmd" or "npm", {
            args = { npm_command, "zx@1" },
            cwd = INSTALL_DIR,
            stdio_sink = context.stdio_sink,
        }, function(success)
            if success then
                has_installed_zx = true
                callback(true)
            else
                context.stdio_sink.stderr "Failed to install zx."
                callback(false)
            end
        end)

        if handle == nil then
            context.stdio_sink.stderr(("Failed to install/update zx. %s"):format(pid))
            callback(false)
        end
    end
end

local function exec(file)
    return function(server, callback, context)
        process.spawn(ZX_EXECUTABLE, {
            args = { file },
            cwd = server.root_dir,
            stdio_sink = context.stdio_sink,
        }, callback)
    end
end

function M.file(relpath)
    local script_path = path.realpath(relpath, 3)
    return installers.compose {
        exec(("file:///%s"):format(script_path)),
        zx_installer(false),
    }
end

return M
