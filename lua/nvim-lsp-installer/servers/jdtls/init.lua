local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local eclipse = require "nvim-lsp-installer.core.clients.eclipse"

return function(name, root_dir)
    ---@param workspace_root string
    ---@param workspace_path string|nil @The path to the server instance's current workspace. Can be nil when running in single file mode.
    local function get_cmd(workspace_root, workspace_path)
        local executable = vim.env.JAVA_HOME and path.concat { vim.env.JAVA_HOME, "bin", "java" } or "java"
        local jar = vim.fn.expand(path.concat { root_dir, "plugins", "org.eclipse.equinox.launcher_*.jar" })
        local lombok = vim.fn.expand(path.concat { root_dir, "lombok.jar" })
        local workspace_dir = vim.fn.fnamemodify(workspace_path or vim.fn.getcwd(), ":p:h:t")

        return {
            platform.is_win and ("%s.exe"):format(executable) or executable,
            "-Declipse.application=org.eclipse.jdt.ls.core.id1",
            "-Dosgi.bundles.defaultStartLevel=4",
            "-Declipse.product=org.eclipse.jdt.ls.core.product",
            "-Dlog.protocol=true",
            "-Dlog.level=ALL",
            "-Xms1g",
            "-Xmx2G",
            "-javaagent:" .. lombok,
            "--add-modules=ALL-SYSTEM",
            "--add-opens",
            "java.base/java.util=ALL-UNNAMED",
            "--add-opens",
            "java.base/java.lang=ALL-UNNAMED",
            "-jar",
            jar,
            "-configuration",
            path.concat {
                root_dir,
                Data.coalesce(
                    Data.when(platform.is_mac, "config_mac"),
                    Data.when(platform.is_linux, "config_linux"),
                    Data.when(platform.is_win, "config_win")
                ),
            },
            "-data",
            path.concat { workspace_root, workspace_dir },
        }
    end

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "java" },
        homepage = "https://github.com/eclipse/eclipse.jdt.ls",
        installer = {
            std.ensure_executables {
                { "java", "java was not found in path." },
            },
            ---@type ServerInstallerFunction
            function(_, callback, ctx)
                if ctx.requested_server_version then
                    callback(true)
                    return
                end
                eclipse.fetch_latest_jdtls_version(function(err, latest_version)
                    if err then
                        ctx.stdio_sink.stderr "Failed to fetch latest verison.\n"
                        callback(false)
                    else
                        ctx.requested_server_version = latest_version
                        callback(true)
                    end
                end)
            end,
            context.capture(function(ctx)
                return std.untargz_remote(
                    ("https://download.eclipse.org/jdtls/snapshots/jdt-language-server-%s.tar.gz"):format(
                        ctx.requested_server_version
                    )
                )
            end),
            std.download_file("https://projectlombok.org/downloads/lombok.jar", "lombok.jar"),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source {
                    type = "jdtls",
                    version = ctx.requested_server_version,
                }
            end),
        },
        default_options = {
            cmd = get_cmd(
                vim.env.WORKSPACE and vim.env.WORKSPACE or path.concat { vim.env.HOME, "workspace" },
                vim.loop.cwd()
            ),
            on_new_config = function(config, workspace_path)
                -- We redefine the cmd in on_new_config because `cmd` will be invalid if the user has not installed
                -- jdtls when starting the session (due to vim.fn.expand returning an empty string, because it can't
                -- locate the file).
                config.cmd = get_cmd(
                    vim.env.WORKSPACE and vim.env.WORKSPACE or path.concat { vim.env.HOME, "workspace" },
                    workspace_path
                )
            end,
        },
    }
end
