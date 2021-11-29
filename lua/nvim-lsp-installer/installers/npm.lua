local path = require "nvim-lsp-installer.path"
local fs = require "nvim-lsp-installer.fs"
local Data = require "nvim-lsp-installer.data"
local installers = require "nvim-lsp-installer.installers"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"

local M = {}

local npm = platform.is_win and "npm.cmd" or "npm"

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

local function create_installer(read_version_from_context)
    ---@param packages string[]
    return function(packages)
        return ensure_npm(
            ---@type ServerInstallerFunction
            function(_, callback, context)
                local pkgs = Data.list_copy(packages or {})
                local c = process.chain {
                    cwd = context.install_dir,
                    stdio_sink = context.stdio_sink,
                }

                -- Use global-style. The reasons for this are:
                --   a) To avoid polluting the executables (aka bin-links) that npm creates.
                --   b) The installation is, after all, more similar to a "global" installation. We don't really gain
                --      any of the benefits of not using global style (e.g., deduping the dependency tree).
                --
                --  We write to .npmrc manually instead of going through npm because managing a local .npmrc file
                --  is a bit unreliable across npm versions (especially <7), so we take extra measures to avoid
                --  inadvertently polluting global npm config.
                fs.append_file(path.concat { context.install_dir, ".npmrc" }, "global-style=true")

                -- stylua: ignore start
                if not (fs.dir_exists(path.concat { context.install_dir, "node_modules" }) or
                       fs.file_exists(path.concat { context.install_dir, "package.json" }))
                then
                    -- Create a package.json to set a boundary for where npm installs packages.
                    c.run(npm, { "init", "--yes", "--scope=lsp-installer" })
                end

                if read_version_from_context and context.requested_server_version and #pkgs > 0 then
                    -- The "head" package is the recipient for the requested version. It's.. by design... don't ask.
                    pkgs[1] = ("%s@%s"):format(pkgs[1], context.requested_server_version)
                end

                -- stylua: ignore end
                c.run(npm, vim.list_extend({ "install" }, pkgs))
                c.spawn(callback)
            end
        )
    end
end

---Creates an installer that installs the provided packages. Will respect user's requested version.
M.packages = create_installer(true)
---Creates an installer that installs the provided packages. Will NOT respect user's requested version.
---This is useful in situation where there's a need to install an auxiliary npm package.
M.install = create_installer(false)

---Creates a server installer that executes the given executable.
---@param executable string
---@param args string[]
function M.exec(executable, args)
    ---@type ServerInstallerFunction
    return function(_, callback, context)
        process.spawn(M.executable(context.install_dir, executable), {
            args = args,
            cwd = context.install_dir,
            stdio_sink = context.stdio_sink,
        }, callback)
    end
end

---Creates a server installer that runs the given script.
---@param script string @The npm script to run (npm run).
function M.run(script)
    return ensure_npm(
        ---@type ServerInstallerFunction
        function(_, callback, context)
            process.spawn(npm, {
                args = { "run", script },
                cwd = context.install_dir,
                stdio_sink = context.stdio_sink,
            }, callback)
        end
    )
end

---@param root_dir string @The directory to resolve the executable from.
---@param executable string
function M.executable(root_dir, executable)
    return path.concat {
        root_dir,
        "node_modules",
        ".bin",
        platform.is_win and ("%s.cmd"):format(executable) or executable,
    }
end

return M
