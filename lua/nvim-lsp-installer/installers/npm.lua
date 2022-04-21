require "nvim-lsp-installer.notify"(
    (
        "%s has been deprecated. See https://github.com/williamboman/nvim-lsp-installer/wiki/Async-infrastructure-changes-notice"
    ):format "nvim-lsp-installer.installers.npm",
    vim.log.levels.WARN
)

local path = require "nvim-lsp-installer.path"
local fs = require "nvim-lsp-installer.fs"
local Data = require "nvim-lsp-installer.data"
local installers = require "nvim-lsp-installer.installers"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"

local list_copy = Data.list_copy

local M = {}

M.npm_command = platform.is_win and "npm.cmd" or "npm"

---@param installer ServerInstallerFunction
local function ensure_npm(installer)
    return installers.pipe {
        std.ensure_executables {
            { "node", "node was not found in path. Refer to https://nodejs.org/en/." },
            {
                "npm",
                "npm was not found in path. Refer to https://docs.npmjs.com/downloading-and-installing-node-js-and-npm.",
            },
        },
        installer,
    }
end

---@param standalone boolean @If true, will run `npm install` as a standalone command, with no consideration to the surrounding installer context (i.e. the requested version in context is ignored, global-style is not applied).
local function create_installer(standalone)
    ---@param packages string[]
    return function(packages)
        return ensure_npm(
            ---@type ServerInstallerFunction
            function(_, callback, ctx)
                local pkgs = list_copy(packages or {})
                local c = process.chain {
                    cwd = ctx.install_dir,
                    stdio_sink = ctx.stdio_sink,
                }

                if not standalone then
                    -- Use global-style. The reasons for this are:
                    --   a) To avoid polluting the executables (aka bin-links) that npm creates.
                    --   b) The installation is, after all, more similar to a "global" installation. We don't really gain
                    --      any of the benefits of not using global style (e.g., deduping the dependency tree).
                    --
                    --  We write to .npmrc manually instead of going through npm because managing a local .npmrc file
                    --  is a bit unreliable across npm versions (especially <7), so we take extra measures to avoid
                    --  inadvertently polluting global npm config.
                    fs.append_file(path.concat { ctx.install_dir, ".npmrc" }, "global-style=true")

                    ctx.receipt:with_primary_source(ctx.receipt.npm(pkgs[1]))
                    for i = 2, #pkgs do
                        ctx.receipt:with_secondary_source(ctx.receipt.npm(pkgs[i]))
                    end
                end

                -- stylua: ignore start
                if not (fs.dir_exists(path.concat { ctx.install_dir, "node_modules" }) or
                       fs.file_exists(path.concat { ctx.install_dir, "package.json" }))
                then
                    -- Create a package.json to set a boundary for where npm installs packages.
                    c.run(M.npm_command, { "init", "--yes", "--scope=lsp-installer" })
                end

                if not standalone and ctx.requested_server_version and #pkgs > 0 then
                    -- The "head" package is the recipient for the requested version. It's.. by design... don't ask.
                    pkgs[1] = ("%s@%s"):format(pkgs[1], ctx.requested_server_version)
                end

                -- stylua: ignore end
                c.run(M.npm_command, vim.list_extend({ "install" }, pkgs))
                c.spawn(callback)
            end
        )
    end
end

---Creates an installer that installs the provided packages. Will respect user's requested version.
M.packages = create_installer(false)

---Creates an installer that installs the provided packages. Will NOT respect user's requested version.
---This is useful in situation where there's a need to install an auxiliary npm package.
M.install = create_installer(true)

---Creates a server installer that executes the given locally installed npm executable.
---@param executable string
---@param args string[]
function M.exec(executable, args)
    ---@type ServerInstallerFunction
    return function(_, callback, ctx)
        process.spawn(executable, {
            args = args,
            cwd = ctx.install_dir,
            stdio_sink = ctx.stdio_sink,
            env = process.graft_env(M.env(ctx.install_dir)),
        }, callback)
    end
end

---Creates a server installer that runs the given script.
---@param script string @The npm script to run (npm run).
function M.run(script)
    return ensure_npm(
        ---@type ServerInstallerFunction
        function(_, callback, ctx)
            process.spawn(M.npm_command, {
                args = { "run", script },
                cwd = ctx.install_dir,
                stdio_sink = ctx.stdio_sink,
            }, callback)
        end
    )
end

---@param root_dir string @The directory to resolve the executable from.
function M.env(root_dir)
    return {
        PATH = process.extend_path { path.concat { root_dir, "node_modules", ".bin" } },
    }
end

return M
