local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    local bin_dir = Data.coalesce(
        Data.when(platform.is_mac, "macOS"),
        Data.when(platform.is_linux, "Linux"),
        Data.when(platform.is_win, "Windows")
    )

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "lua" },
        homepage = "https://github.com/sumneko/lua-language-server",
        installer = {
            context.use_github_release_file("sumneko/vscode-lua", function(version)
                return ("lua-%s.vsix"):format(version:gsub("^v", ""))
            end),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
            -- see https://github.com/sumneko/vscode-lua/pull/43
            std.chmod(
                "+x",
                { "extension/server/bin/macOS/lua-language-server", "extension/server/bin/Linux/lua-language-server" }
            ),
        },
        default_options = {
            cmd = { path.concat { root_dir, "extension", "server", "bin", bin_dir, "lua-language-server" } },
        },
    }
end
