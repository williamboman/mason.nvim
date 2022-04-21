require "nvim-lsp-installer.notify"(
    (
        "%s has been deprecated. See https://github.com/williamboman/nvim-lsp-installer/wiki/Async-infrastructure-changes-notice"
    ):format "nvim-lsp-installer.installers.pip3",
    vim.log.levels.WARN
)

local path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"
local installers = require "nvim-lsp-installer.installers"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"
local settings = require "nvim-lsp-installer.settings"
local context = require "nvim-lsp-installer.installers.context"
local log = require "nvim-lsp-installer.log"

local M = {}

local REL_INSTALL_DIR = "venv"

---@param python_executable string
---@param packages string[]
local function create_installer(python_executable, packages)
    return installers.pipe {
        std.ensure_executables {
            {
                python_executable,
                ("%s was not found in path. Refer to https://www.python.org/downloads/."):format(python_executable),
            },
        },
        ---@type ServerInstallerFunction
        function(_, callback, ctx)
            local pkgs = Data.list_copy(packages or {})
            local c = process.chain {
                cwd = ctx.install_dir,
                stdio_sink = ctx.stdio_sink,
                env = process.graft_env(M.env(ctx.install_dir)),
            }

            ctx.receipt:with_primary_source(ctx.receipt.pip3(pkgs[1]))
            for i = 2, #pkgs do
                ctx.receipt:with_secondary_source(ctx.receipt.pip3(pkgs[i]))
            end

            c.run(python_executable, { "-m", "venv", REL_INSTALL_DIR })
            if ctx.requested_server_version then
                -- The "head" package is the recipient for the requested version. It's.. by design... don't ask.
                pkgs[1] = ("%s==%s"):format(pkgs[1], ctx.requested_server_version)
            end

            local install_command = { "-m", "pip", "install", "-U" }
            vim.list_extend(install_command, settings.current.pip.install_args)
            c.run("python", vim.list_extend(install_command, pkgs))

            c.spawn(callback)
        end,
    }
end

---@param packages string[] @The pip packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
function M.packages(packages)
    local py3 = create_installer("python3", packages)
    local py = create_installer("python", packages)
    -- see https://github.com/williamboman/nvim-lsp-installer/issues/128
    local installer_variants = platform.is_win and { py, py3 } or { py3, py }

    local py3_host_prog = vim.g.python3_host_prog
    if py3_host_prog then
        log.fmt_trace("Found python3_host_prog (%s)", py3_host_prog)
        table.insert(installer_variants, 1, create_installer(py3_host_prog, packages))
    end

    return installers.pipe {
        context.promote_install_dir(),
        installers.first_successful(installer_variants),
    }
end

---@param root_dir string @The directory to resolve the executable from.
function M.env(root_dir)
    return {
        PATH = process.extend_path { M.path(root_dir) },
    }
end

function M.path(root_dir)
    return path.concat { root_dir, REL_INSTALL_DIR, platform.is_win and "Scripts" or "bin" }
end

return M
