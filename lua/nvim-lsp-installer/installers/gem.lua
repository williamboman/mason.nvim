local path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"
local process = require "nvim-lsp-installer.process"
local installers = require "nvim-lsp-installer.installers"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"

local M = {}

local gem = platform.is_win and "gem.cmd" or "gem"

function M.packages(packages)
    return installers.pipe {
        std.ensure_executables {
            { "ruby", "ruby was not found in path, refer to https://wiki.openstack.org/wiki/RubyGems." },
            { "gem", "gem was not found in path, refer to https://wiki.openstack.org/wiki/RubyGems." },
        },
        function(server, callback, context)
            local pkgs = Data.list_copy(packages or {})
            if context.requested_server_version then
                -- The "head" package is the recipient for the requested version. It's.. by design... don't ask.
                pkgs[1] = ("%s:%s"):format(pkgs[1], context.requested_server_version)
            end

            process.spawn(gem, {
                args = {
                    "install",
                    "--no-user-install",
                    "--install-dir=.",
                    "--bindir=bin",
                    "--no-document",
                    table.concat(pkgs, " "),
                },
                cwd = server.root_dir,
                stdio_sink = context.stdio_sink,
            }, callback)
        end,
    }
end

function M.executable(root_dir, executable)
    return path.concat { root_dir, "bin", executable }
end

function M.env(root_dir)
    return {
        GEM_HOME = root_dir,
        GEM_PATH = root_dir,
    }
end

return M
