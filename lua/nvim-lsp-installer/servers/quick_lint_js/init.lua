local server = require "nvim-lsp-installer.server"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local platform = require "nvim-lsp-installer.platform"
local path = require "nvim-lsp-installer.path"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://quick-lint-js.com/",
        languages = { "javascript" },
        installer = {
            context.use_github_latest_tag "quick-lint/quick-lint-js",
            context.capture(function(ctx)
                local url = "https://c.quick-lint-js.com/releases/%s/manual/%s%s"
                if platform.is_mac then
                    return std.untargz_remote(url:format(ctx.requested_server_version, "macos", ".tar.gz"))
                elseif platform.is_windows then
                    return std.unzip_remote(url:format(ctx.requested_server_version, "windows", ".zip"))
                elseif platform.is_linux then
                    return std.untargz_remote(url:format(ctx.requested_server_version, "linux", ".tar.gz"))
                end
            end),
        },
        default_options = {
            cmd = { path.concat { root_dir, "quick-lint-js", "bin", "quick-lint-js" }, "--lsp-server" },
        },
    }
end
