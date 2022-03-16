local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"
local installers = require "nvim-lsp-installer.installers"
local process = require "nvim-lsp-installer.process"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    local solang_executable_installer = installers.pipe {
        context.use_github_release_file(
            "hyperledger-labs/solang",
            coalesce(
                when(platform.is_mac and platform.arch == "x64", "solang-mac-intel"),
                when(platform.is_mac and platform.arch == "arm64", "solang-mac-arm"),
                when(platform.is_linux and platform.arch == "arm64", "solang-linux-arm64"),
                when(platform.is_linux and platform.arch == "x64", "solang-linux-x86-64"),
                when(platform.is_win, "solang.exe")
            )
        ),
        context.capture(function(ctx)
            return std.download_file(ctx.github_release_file, platform.is_win and "solang.exe" or "solang")
        end),
        std.chmod("+x", { "solang" }),
        context.receipt(function(receipt, ctx)
            receipt:with_primary_source(receipt.github_release_file(ctx))
        end),
    }

    local llvm_installer = installers.pipe {
        context.use_github_release_file(
            "hyperledger-labs/solang",
            coalesce(
                when(platform.is_mac and platform.arch == "x64", "llvm13.0-mac-intel.tar.xz"),
                when(platform.is_mac and platform.arch == "arm64", "llvm13.0-mac-arm.tar.xz"),
                when(platform.is_linux and platform.arch == "x64", "llvm13.0-linux-x86-64.tar.xz"),
                when(platform.is_linux and platform.arch == "arm64", "llvm13.0-linux-arm64.tar.xz"),
                when(platform.is_win, "llvm13.0-win.zip")
            )
        ),
        context.capture(function(ctx)
            if platform.is_win then
                return std.unzip_remote(ctx.github_release_file)
            else
                return std.untarxz_remote(ctx.github_release_file)
            end
        end),
    }

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://solang.readthedocs.io/en/latest/",
        languages = { "solidity" },
        installer = {
            solang_executable_installer,
            llvm_installer,
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path {
                    path.concat { root_dir },
                    path.concat { root_dir, "llvm13.0", "bin" },
                    path.concat { root_dir, "llvm12.0", "bin" }, -- kept for backwards compatibility
                },
            },
        },
    }
end
