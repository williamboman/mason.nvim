local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local installers = require "nvim-lsp-installer.installers"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"
local context = require "nvim-lsp-installer.installers.context"
local process = require "nvim-lsp-installer.process"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    local llvm_installer

    do
        ---@param version string
        ---@param os_distribution table<string, string>|nil
        ---@return string|nil
        local function get_archive_name(version, os_distribution)
            local name_template = coalesce(
                when(platform.is_mac, "clang+llvm-%s-x86_64-apple-darwin"),
                when(
                    platform.is_linux,
                    coalesce(
                        when(
                            platform.arch == "x64",
                            coalesce(
                                when(
                                    os_distribution.id == "ubuntu" and os_distribution.version.major >= 20,
                                    "clang+llvm-%s-x86_64-linux-gnu-ubuntu-20.04"
                                ),
                                when(
                                    os_distribution.id == "ubuntu" and os_distribution.version.major >= 16,
                                    "clang+llvm-%s-x86_64-linux-gnu-ubuntu-16.04"
                                ),
                                -- the Ubuntu dist is allegedly the most suitable cross-platform one, so we default to it
                                "clang+llvm-%s-x86_64-linux-gnu-ubuntu-16.04"
                            )
                        ),
                        when(platform.arch == "arm64", "clang+llvm-%s-aarch64-linux-gnu"),
                        when(platform.arch == "armv7", "clang+llvm-%s-armv7a-linux-gnueabihf"),
                        when(platform.arch == "x86", "clang+llvm-%s-i386-unknown-freebsd13")
                    )
                )
            )
            return name_template and name_template:format(version)
        end

        ---@param version string
        local function normalize_version(version)
            local s = version:gsub("^llvmorg%-", "")
            return s
        end

        llvm_installer = installers.branch_context {
            context.set(function(ctx)
                -- We unset the requested version for llvm because it's not the primary target - the user's requested version should only apply to ccls.
                ctx.requested_server_version = nil
            end),
            context.capture(function(ctx)
                return context.use_github_release_file("llvm/llvm-project", function(version)
                    -- Strip the "llvmorg-" prefix from tags (llvm releases tags like llvmorg-13.0.0)
                    local archive_name = get_archive_name(normalize_version(version), ctx.os_distribution)
                    return archive_name and ("%s.tar.xz"):format(archive_name)
                end)
            end),
            context.capture(function(ctx)
                return installers.pipe {
                    std.untarxz_remote(ctx.github_release_file),
                    std.rename(
                        get_archive_name(normalize_version(ctx.requested_server_version), ctx.os_distribution),
                        "llvm"
                    ),
                    std.rename(
                        path.concat { "llvm", "lib", "clang", normalize_version(ctx.requested_server_version) },
                        "clang-resource"
                    ),
                }
            end),
        }
    end

    local ccls_installer = installers.branch_context {
        context.set(function(ctx)
            ctx.llvm_install_dir = path.concat { ctx.install_dir, "llvm" }
            ctx.clang_resource_dir = path.concat { ctx.install_dir, "clang-resource" }
        end),
        installers.branch_context {
            context.set_working_dir "ccls-git",
            std.git_clone "https://github.com/MaskRay/ccls",
            std.git_submodule_update(),
            function(_, callback, ctx)
                local c = process.chain {
                    cwd = ctx.install_dir,
                    stdio_sink = ctx.stdio_sink,
                }

                c.run("cmake", {
                    "-H.",
                    "-BRelease",
                    "-DCMAKE_BUILD_TYPE=Release",
                    ("-DCMAKE_PREFIX_PATH=%s"):format(ctx.llvm_install_dir),
                    ("-DCLANG_RESOURCE_DIR=%s"):format(ctx.clang_resource_dir),
                })
                c.run("cmake", { "--build", "Release" })
                c.spawn(callback)
            end,
        },
        std.rename(path.concat { "ccls-git", "Release", "ccls" }, "ccls"),
    }

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/MaskRay/ccls",
        languages = { "c", "c++", "objective-c" },
        installer = installers.when {
            unix = {
                context.use_os_distribution(),
                context.promote_install_dir(), -- ccls hardcodes the path to llvm at compile time, so we need to compile everything in the final directory
                llvm_installer,
                ccls_installer,
                std.rmrf "llvm",
                std.rmrf "ccls-git",
            },
        },
        default_options = {
            cmd = { path.concat { root_dir, "ccls" } },
        },
    }
end
