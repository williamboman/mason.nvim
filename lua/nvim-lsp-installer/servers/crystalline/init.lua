local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.core.process"
local platform = require "nvim-lsp-installer.core.platform"
local functional = require "nvim-lsp-installer.core.functional"
local path = require "nvim-lsp-installer.core.path"
local github = require "nvim-lsp-installer.core.managers.github"
local std = require "nvim-lsp-installer.core.managers.std"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/elbywan/crystalline",
        languages = { "crystal" },
        installer = function()
            github.gunzip_release_file({
                repo = "elbywan/crystalline",
                asset_file = coalesce(
                    when(platform.is_mac and platform.arch == "x64", "crystalline_x86_64-apple-darwin.gz"),
                    when(platform.is_linux and platform.arch == "x64", "crystalline_x86_64-unknown-linux-gnu.gz")
                ),
                out_file = "crystalline",
            }).with_receipt()
            std.chmod("+x", { "crystalline" })
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir, path.concat { root_dir, "crystal", "bin" } },
            },
        },
    }
end
