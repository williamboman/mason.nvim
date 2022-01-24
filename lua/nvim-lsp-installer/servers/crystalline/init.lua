local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local installers = require "nvim-lsp-installer.installers"
local Data = require "nvim-lsp-installer.data"
local path = require "nvim-lsp-installer.path"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/elbywan/crystalline",
        languages = { "crystal" },
        installer = {
            -- Crystalline (LSP)
            installers.branch_context {
                context.use_github_release_file(
                    "elbywan/crystalline",
                    coalesce(
                        when(platform.is_mac and platform.arch == "x64", "crystalline_x86_64-apple-darwin.gz"),
                        when(platform.is_linux and platform.arch == "x64", "crystalline_x86_64-unknown-linux-gnu.gz")
                    )
                ),
                context.capture(function(ctx)
                    return std.gunzip_remote(
                        ctx.github_release_file,
                        platform.is_win and "crystalline.exe" or "crystalline"
                    )
                end),
                std.chmod("+x", { "crystalline" }),
                context.receipt(function(receipt, ctx)
                    receipt:with_primary_source(receipt.github_release_file(ctx))
                end),
            },
            -- Crystal
            installers.branch_context {
                context.use_github_release_file("crystal-lang/crystal", function(version)
                    local target_file = coalesce(
                        when(platform.is_mac, "crystal-%s-1-darwin-universal.tar.gz"),
                        when(platform.is_linux and platform.arch == "x64", "crystal-%s-1-linux-x86_64-bundled.tar.gz")
                    )
                    return target_file and target_file:format(version)
                end),
                context.capture(function(ctx)
                    return installers.pipe {
                        std.untargz_remote(ctx.github_release_file),
                        std.rename(("crystal-%s-1"):format(ctx.requested_server_version), "crystal"),
                    }
                end),
                std.chmod("+x", { "crystalline" }),
                context.receipt(function(receipt, ctx)
                    receipt:with_secondary_source(receipt.github_release_file(ctx))
                end),
            },
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir, path.concat { root_dir, "crystal", "bin" } },
            },
        },
    }
end
