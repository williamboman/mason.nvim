local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = {
            context.github_release_file("hashicorp/terraform-ls", function(version)
                return Data.coalesce(
                    Data.when(
                        platform.is_mac,
                        Data.coalesce(
                            Data.when(platform.arch == "arm64", "terraform-ls_%s_darwin_arm64.zip"),
                            Data.when(platform.arch == "x64", "terraform-ls_%s_darwin_amd64.zip")
                        )
                    ),
                    Data.when(
                        platform.is_linux,
                        Data.coalesce(
                            Data.when(platform.arch == "arm64", "terraform-ls_%s_linux_arm64.zip"),
                            Data.when(platform.arch == "arm", "terraform-ls_%s_linux_arm.zip"),
                            Data.when(platform.arch == "x64", "terraform-ls_%s_linux_amd64.zip")
                        )
                    ),
                    Data.when(
                        platform.is_win,
                        Data.coalesce(Data.when(platform.arch == "x64", "terraform-ls_%s_windows_amd64.zip"))
                    )
                ):format(version:gsub("^v", ""))
            end),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file, "terraform-ls")
            end),
        },
        default_options = {
            cmd = { path.concat { root_dir, "terraform-ls", "terraform-ls" }, "serve" },
        },
    }
end
