local path = require "mason-core.path"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"

---@param install_dir string
return function(install_dir)
    ---@param workspace_root string
    ---@param workspace_path string|nil @The path to the server instance's current workspace. Can be nil when running in single file mode.
    ---@param vmargs string[]
    ---@param use_lombok_agent boolean
    local function get_cmd(workspace_root, workspace_path, vmargs, use_lombok_agent)
        local executable = vim.env.JAVA_HOME and path.concat { vim.env.JAVA_HOME, "bin", "java" } or "java"
        local jar = vim.fn.expand(path.concat { install_dir, "plugins", "org.eclipse.equinox.launcher_*.jar" })
        local lombok = vim.fn.expand(path.concat { install_dir, "lombok.jar" })
        local workspace_dir = vim.fn.fnamemodify(workspace_path or vim.fn.getcwd(), ":p:h:t")

        local cmd = _.list_not_nil(
            platform.is_win and ("%s.exe"):format(executable) or executable,
            "-Declipse.application=org.eclipse.jdt.ls.core.id1",
            "-Dosgi.bundles.defaultStartLevel=4",
            "-Declipse.product=org.eclipse.jdt.ls.core.product",
            _.when(platform.is.win, "-DwatchParentProcess=false"), -- https://github.com/redhat-developer/vscode-java/pull/847
            "--add-modules=ALL-SYSTEM",
            "--add-opens",
            "java.base/java.util=ALL-UNNAMED",
            "--add-opens",
            "java.base/java.lang=ALL-UNNAMED",
            "--add-opens",
            "java.base/sun.nio.fs=ALL-UNNAMED", -- https://github.com/redhat-developer/vscode-java/issues/2264
            _.when(use_lombok_agent, "-javaagent:" .. lombok), -- javaagent needs to come before -jar flag
            "-jar",
            jar,
            "-configuration",
            path.concat {
                install_dir,
                _.coalesce(
                    _.when(platform.is.mac, "config_mac"),
                    _.when(platform.is.linux, "config_linux"),
                    _.when(platform.is.win, "config_win")
                ),
            },
            "-data",
            path.concat { workspace_root, workspace_dir }
        )

        return vim.list_extend(cmd, vmargs)
    end

    local DEFAULT_VMARGS = {
        "-XX:+UseParallelGC",
        "-XX:GCTimeRatio=4",
        "-XX:AdaptiveSizePolicyWeight=90",
        "-Dsun.zip.disableMemoryMapping=true",
        "-Djava.import.generatesMetadataFilesAtProjectRoot=false",
        "-Xmx1G",
        "-Xms100m",
    }

    return {
        cmd = get_cmd(
            vim.env.WORKSPACE and vim.env.WORKSPACE or path.concat { vim.env.HOME, "workspace" },
            vim.loop.cwd(),
            DEFAULT_VMARGS,
            false
        ),
        on_new_config = function(config, workspace_path)
            -- We redefine the cmd in on_new_config because `cmd` will be invalid if the user has not installed
            -- jdtls when starting the session (due to vim.fn.expand returning an empty string, because it can't
            -- locate the file).
            config.cmd = get_cmd(
                vim.env.WORKSPACE and vim.env.WORKSPACE or path.concat { vim.env.HOME, "workspace" },
                workspace_path,
                config.vmargs or DEFAULT_VMARGS,
                config.use_lombok_agent or false
            )
        end,
    }
end
