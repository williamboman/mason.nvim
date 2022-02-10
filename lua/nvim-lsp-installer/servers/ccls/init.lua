--  __________________
-- < Here be dragons! >
--  ------------------
--                        \                    ^    /^
--                         \                  / \  // \
--                          \   |\___/|      /   \//  .\
--                           \  /O  O  \__  /    //  | \ \           *----*
--                             /     /  \/_/    //   |  \  \          \   |
--                             @___@`    \/_   //    |   \   \         \/\ \
--                            0/0/|       \/_ //     |    \    \         \  \
--                        0/0/0/0/|        \///      |     \     \       |  |
--                     0/0/0/0/0/_|_ /   (  //       |      \     _\     |  /
--                  0/0/0/0/0/0/`/,_ _ _/  ) ; -.    |    _ _\.-~       /   /
--                              ,-}        _      *-.|.-~-.           .~    ~
--             \     \__/        `/\      /                 ~-. _ .-~      /
--              \____(@@)           *.   }            {                   /
--              (    (--)          .----~-.\        \-`                 .~
--              //__\\  \__ Ack!   ///.----..<        \             _ -~
--             //    \\               ///-._ _ _ _ _ _ _{^ - - - - ~
--

local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local installers = require "nvim-lsp-installer.installers"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"
local context = require "nvim-lsp-installer.installers.context"
local process = require "nvim-lsp-installer.process"
local fs = require "nvim-lsp-installer.fs"

local coalesce, when, list_not_nil = Data.coalesce, Data.when, Data.list_not_nil

return function(name, root_dir)
    local llvm_installer

    do
        ---@param version string
        ---@param os_distribution table<string, string>|nil
        ---@return string|nil
        local function get_archive_name(version, os_distribution)
            local name_template = coalesce(
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
                                )
                            )
                        ),
                        when(platform.arch == "arm64", "clang+llvm-%s-aarch64-linux-gnu"),
                        when(platform.arch == "armv7", "clang+llvm-%s-armv7a-linux-gnueabihf")
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
            context.use_os_distribution(),
            context.set(function(ctx)
                -- We unset the requested version for llvm because it's not the primary target - the user's requested version should only apply to ccls.
                ctx.requested_server_version = nil
            end),
            installers.first_successful {
                installers.pipe {
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
                            -- We move the clang headers out, because they need to be persisted
                            std.rename(
                                path.concat { "llvm", "lib", "clang", normalize_version(ctx.requested_server_version) },
                                "clang-resource"
                            ),
                        }
                    end),
                },
                -- If the previous step fails, default to building using system clang+llvm.
                context.set(function(ctx)
                    ctx.stdio_sink.stdout "\nUsing system clang+LLVM! Build will fail if clang/LLVM is not installed on the system.\n"
                    ctx.use_system_llvm = true
                end),
            },
        }
    end

    local ccls_installer = installers.pipe {
        std.git_clone("https://github.com/MaskRay/ccls", {
            directory = "ccls-git",
            recursive = true,
        }),
        function(srv, callback, ctx)
            local c = process.chain {
                cwd = path.concat { ctx.install_dir, "ccls-git" },
                stdio_sink = ctx.stdio_sink,
            }

            local clang_resource_dir = path.concat { srv.root_dir, "clang-resource" }

            c.run(
                "cmake",
                list_not_nil(
                    "-DCMAKE_BUILD_TYPE=Release",
                    "-DUSE_SYSTEM_RAPIDJSON=OFF",
                    "-DCMAKE_FIND_FRAMEWORK=LAST",
                    "-Wno-dev",
                    ("-DCMAKE_INSTALL_PREFIX=%s"):format(ctx.install_dir),
                    when(not ctx.use_system_llvm, ("-DCMAKE_PREFIX_PATH=%s"):format(ctx.llvm_dir)),
                    when(
                        not platform.is_mac and not ctx.use_system_llvm,
                        ("-DCLANG_RESOURCE_DIR=%s"):format(clang_resource_dir)
                    ),
                    when(platform.is_mac, "-DCMAKE_OSX_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk")
                )
            )
            c.run("make", { "install" })
            c.spawn(callback)
        end,
        std.rmrf "ccls-git",
    }

    local linux_ccls_installer = installers.pipe {
        llvm_installer,
        context.set(function(ctx)
            ctx.llvm_dir = path.concat { ctx.install_dir, "llvm" }
        end),
        ccls_installer,
        installers.always_succeed(std.rmrf "llvm"),
    }

    local mac_ccls_installer = installers.pipe {
        context.use_homebrew_prefix(),
        context.set(function(ctx)
            ctx.llvm_dir = path.concat { ctx.homebrew_prefix, "opt", "llvm", "lib", "cmake" }
        end),
        function(_, callback, ctx)
            if not fs.dir_exists(ctx.llvm_dir) then
                ctx.stdio_sink.stderr(
                    (
                        "LLVM does not seem to be installed on this system (looked in %q). Please install LLVM via Homebrew:\n  $ brew install llvm\n"
                    ):format(ctx.llvm_dir)
                )
                callback(false)
                return
            end
            callback(true)
        end,
        ccls_installer,
    }

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/MaskRay/ccls",
        languages = { "c", "c++", "objective-c" },
        installer = {
            installers.when {
                mac = mac_ccls_installer,
                linux = linux_ccls_installer,
            },
            context.receipt(function(receipt)
                -- The cloned ccls git repo gets deleted during installation, so we have no local copy.
                receipt:mark_invalid()
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "bin" } },
            },
        },
    }
end
