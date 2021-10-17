local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"
local installers = require "nvim-lsp-installer.installers"

local uv = vim.loop

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://valentjn.github.io/vscode-ltex",
        installer = {
            context.use_github_release_file("valentjn/ltex-ls", function(version)
                return coalesce(
                    when(platform.is_mac, "ltex-ls-%s-mac-x64.tar.gz"),
                    when(platform.is_linux, "ltex-ls-%s-linux-x64.tar.gz"),
                    when(platform.is_win, "ltex-ls-%s-windows-x64.zip")
                ):format(version)
            end),
            context.capture(function(ctx)
                if platform.is_win then
                    -- todo strip components unzip
                    return std.unzip_remote(ctx.github_release_file)
                else
                    return std.untargz_remote(ctx.github_release_file)
                end
            end),
            installers.when {
                unix = function(server, callback, context)
                    local executable = path.concat {
                        server.root_dir,
                        ("ltex-ls-%s"):format(context.requested_server_version),
                        "bin",
                        "ltex-ls",
                    }
                    local new_path = path.concat { server.root_dir, "ltex-ls" }
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
                    context.stdio_sink.stdout "Creating ltex-ls.bat...\n"
                    uv.fs_open(path.concat { server.root_dir, "ltex-ls.bat" }, "w", 438, function(open_err, fd)
                        local executable = path.concat {
                            server.root_dir,
                            ("ltex-ls-%s"):format(context.requested_server_version),
                            "bin",
                            "ltex-ls.bat",
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
                                context.stdio_sink.stdout "Created ltex-ls.bat\n"
                                callback(true)
                            end
                            assert(uv.fs_close(fd))
                        end)
                    end)
                end,
            },
        },
        pre_setup = function()
            require "nvim-lsp-installer.servers.ltex.configure"
        end,
        default_options = {
            cmd = { path.concat { root_dir, platform.is_win and "ltex-ls.bat" or "ltex-ls" } },
        },
    }
end
