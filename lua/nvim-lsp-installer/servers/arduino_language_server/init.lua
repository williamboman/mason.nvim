local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.core.platform"
local functional = require "nvim-lsp-installer.core.functional"
local github = require "nvim-lsp-installer.core.managers.github"
local process = require "nvim-lsp-installer.core.process"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/arduino/arduino-language-server",
        languages = { "arduino" },
        installer = function()
            local opts = {
                repo = "arduino/arduino-language-server",
                asset_file = function(release)
                    local target = coalesce(
                        when(platform.is_mac, "arduino-language-server_%s_macOS_64bit.tar.gz"),
                        when(
                            platform.is_linux and platform.arch == "x64",
                            "arduino-language-server_%s_Linux_64bit.tar.gz"
                        ),
                        when(
                            platform.is_linux and platform.arch == "x86",
                            "arduino-language-server_%s_Linux_32bit.tar.gz"
                        ),
                        when(
                            platform.is_linux and platform.arch == "arm64",
                            "arduino-language-server_%s_Linux_ARM64.tar.gz"
                        ),
                        when(
                            platform.is_win and platform.arch == "x64",
                            "arduino-language-server_0.6.0_Windows_64bit.zip"
                        ),
                        when(
                            platform.is_win and platform.arch == "x86",
                            "arduino-language-server_0.6.0_Windows_32bit.zip"
                        )
                    )

                    return target and target:format(release)
                end,
            }

            platform.when {
                unix = function()
                    github.untargz_release_file(opts).with_receipt()
                end,
                win = function()
                    github.unzip_release_file(opts).with_receipt()
                end,
            }
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
