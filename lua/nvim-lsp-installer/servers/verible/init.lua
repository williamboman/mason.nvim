local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.core.process"
local platform = require "nvim-lsp-installer.core.platform"
local functional = require "nvim-lsp-installer.core.functional"
local path = require "nvim-lsp-installer.core.path"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://chipsalliance.github.io/verible/",
        languages = { "systemverilog", "verilog" },
        ---@param ctx InstallContext
        installer = function(ctx)
            local repo = "chipsalliance/verible"
            platform.when {
                linux = function()
                    local os_dist = platform.os_distribution()
                    local source = github.untarxz_release_file {
                        repo = repo,
                        asset_file = function(release)
                            if os_dist.id == "ubuntu" then
                                local target_file = when(
                                    platform.arch == "x64",
                                    coalesce(
                                        when(
                                            os_dist.version.major == 16,
                                            "verible-%s-Ubuntu-16.04-xenial-x86_64.tar.gz"
                                        ),
                                        when(
                                            os_dist.version.major == 18,
                                            "verible-%s-Ubuntu-18.04-bionic-x86_64.tar.gz"
                                        ),
                                        when(os_dist.version.major == 20, "verible-%s-Ubuntu-20.04-focal-x86_64.tar.gz"),
                                        when(os_dist.version.major == 22, "verible-%s-Ubuntu-22.04-jammy-x86_64.tar.gz")
                                    )
                                )
                                return target_file and target_file:format(release)
                            end
                        end,
                    }
                    source.with_receipt()
                    ctx.fs:rename(("verible-%s"):format(source.release), "verible")
                end,
                win = function()
                    local source = github.unzip_release_file {
                        repo = repo,
                        asset_file = function(release)
                            local target_file = coalesce(when(platform.arch == "x64", "verible-%s-win64.zip"))
                            return target_file and target_file:format(release)
                        end,
                    }
                    source.with_receipt()
                    ctx.fs:rename(("verible-%s-win64"):format(source.release), "verible")
                end,
            }
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path {
                    path.concat(coalesce(
                        when(platform.is_win, { root_dir, "verible" }),
                        when(platform.is_unix, { root_dir, "verible", "bin" }),
                        { root_dir, "verible", "bin" } -- default
                    )),
                },
            },
        },
    }
end
