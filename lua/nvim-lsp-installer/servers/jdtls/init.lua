local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"

return function(name, root_dir)
    local function get_cmd(workspace_name)
        local executable = vim.env.JAVA_HOME and path.concat { vim.env.JAVA_HOME, "bin", "java" } or "java"
        local jar = vim.fn.expand(path.concat { root_dir, "plugins", "org.eclipse.equinox.launcher_*.jar" })
        local lombok = vim.fn.expand(path.concat { root_dir, "lombok.jar" })
        local workspace_dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

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
            path.concat { workspace_name, workspace_dir },
        }
    end

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "java" },
        homepage = "https://github.com/eclipse/eclipse.jdt.ls",
        installer = {
            context.capture(function(ctx)
                local version = ctx.requested_server_version or "latest"
                return std.untargz_remote(
                    ("https://download.eclipse.org/jdtls/snapshots/jdt-language-server-%s.tar.gz"):format(version)
                )
            end),
            std.download_file("https://projectlombok.org/downloads/lombok.jar", "lombok.jar"),
        },
        default_options = {
            cmd = get_cmd(vim.env.WORKSPACE and vim.env.WORKSPACE or path.concat { vim.env.HOME, "workspace" }),
        },
    }
end
