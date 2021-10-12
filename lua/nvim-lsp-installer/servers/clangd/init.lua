local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"
local context = require "nvim-lsp-installer.installers.context"
local installers = require "nvim-lsp-installer.installers"

local uv = vim.loop

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://clangd.llvm.org",
        installer = {
            context.github_release_file("clangd/clangd", function(version)
                return Data.coalesce(
                    Data.when(platform.is_mac, "clangd-mac-%s.zip"),
                    Data.when(platform.is_linux and platform.arch == "x64", "clangd-linux-%s.zip"),
                    Data.when(platform.is_win, "clangd-windows-%s.zip")
                ):format(version)
            end),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
            installers.when {
                unix = function(server, callback, context)
                    local executable = path.concat {
                        server.root_dir,
                        ("clangd_%s"):format(context.requested_server_version),
                        "bin",
                        "clangd",
                    }
                    local new_path = path.concat { server.root_dir, "clangd" }
                    context.stdio_sink.stdout(("Creating symlink from %s to %s\n"):format(executable, new_path))
                    uv.fs_symlink(executable, new_path, { dir = false, junction = false }, function(err, success)
                        if not success then
                            context.stdio_sink.stderr(tostring(err) .. "\n")
                            callback(false)
                        else
                            callback(true)
                        end
                    end)
                end,
                win = function(server, callback, context)
                    context.stdio_sink.stdout "Creating clangd.bat...\n"
                    uv.fs_open(path.concat { server.root_dir, "clangd.bat" }, "w", 438, function(open_err, fd)
                        local executable = path.concat {
                            server.root_dir,
                            ("clangd_%s"):format(context.requested_server_version),
                            "bin",
                            "clangd.exe",
                        }
                        if open_err then
                            context.stdio_sink.stderr(tostring(open_err) .. "\n")
                            return callback(false)
                        end
                        uv.fs_write(fd, ("@call %q %%*"):format(executable), -1, function(write_err)
                            if write_err then
                                context.stdio_sink.stderr(tostring(write_err) .. "\n")
                                callback(false)
                            else
                                context.stdio_sink.stdout "Created clangd.bat\n"
                                callback(true)
                            end
                            assert(uv.fs_close(fd))
                        end)
                    end)
                end,
            },
        },
        default_options = {
            cmd = { path.concat { root_dir, platform.is_win and "clangd.bat" or "clangd" } },
        },
    }
end
