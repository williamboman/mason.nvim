local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://1c-syntax.github.io/bsl-language-server",
        languages = { "onescript" },
        installer = {
            std.ensure_executables {
                { "java", "java was not found in path." },
            },
            context.use_github_release_file("1c-syntax/bsl-language-server", function(tag)
                local version = tag:gsub("^v", "")
                return ("bsl-language-server-%s-exec.jar"):format(version)
            end),
            context.capture(function(ctx)
                return std.download_file(ctx.github_release_file, "bsl-lsp.jar")
            end),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source(receipt.github_release_file(ctx))
            end),
        },
        default_options = {
            cmd = {
                "java",
                "-jar",
                path.concat { root_dir, "bsl-lsp.jar" },
            },
        },
    }
end
