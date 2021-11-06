local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/latex-lsp/texlab",
        languages = { "latex" },
        installer = {
            context.use_github_release_file(
                "latex-lsp/texlab",
                coalesce(
                    when(platform.is_mac, "texlab-x86_64-macos.tar.gz"),
                    when(platform.is_linux, "texlab-x86_64-linux.tar.gz"),
                    when(platform.is_win, "texlab-x86_64-windows.tar.gz")
                )
            ),
            context.capture(function(ctx)
                return std.untargz_remote(ctx.github_release_file)
            end),
        },
        default_options = {
            cmd = { path.concat { root_dir, "texlab" } },
        },
    }
end
