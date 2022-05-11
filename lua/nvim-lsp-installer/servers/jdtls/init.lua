local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local platform = require "nvim-lsp-installer.core.platform"
local functional = require "nvim-lsp-installer.core.functional"
local installer = require "nvim-lsp-installer.core.installer"
local eclipse = require "nvim-lsp-installer.core.clients.eclipse"
local std = require "nvim-lsp-installer.core.managers.std"

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
                functional.coalesce(
                    functional.when(platform.is_mac, "config_mac"),
                    functional.when(platform.is_linux, "config_linux"),
                    functional.when(platform.is_win, "config_win")
                ),
            },
            "-data",
            path.concat { workspace_root, workspace_dir },
        }
    end

    local function download_jdtls()
        local ctx = installer.context()
        local version = ctx.requested_version:or_else_get(function()
            return eclipse.fetch_latest_jdtls_version():get_or_throw()
        end)

        std.download_file(
            ("https://download.eclipse.org/jdtls/snapshots/jdt-language-server-%s.tar.gz"):format(version),
            "archive.tar.gz"
        )
        std.untar "archive.tar.gz"

        ctx.receipt:with_primary_source {
            type = "jdtls",
            version = version,
        }
    end

    local function download_lombok()
        std.download_file("https://projectlombok.org/downloads/lombok.jar", "lombok.jar")
    end

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "java" },
        homepage = "https://github.com/eclipse/eclipse.jdt.ls",
        ---@param ctx InstallContext
        installer = function(ctx)
            std.ensure_executable "java"
            ctx:run_concurrently { download_jdtls, download_lombok }
        end,
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
