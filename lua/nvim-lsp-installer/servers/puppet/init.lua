local server = require "nvim-lsp-installer.server"
local context = require "nvim-lsp-installer.installers.context"
local std = require "nvim-lsp-installer.installers.std"
local process = require "nvim-lsp-installer.process"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/puppetlabs/puppet-editor-services",
        languages = { "puppet" },
        installer = {
            context.use_github_release_file("puppetlabs/puppet-editor-services", function(version)
                return ("puppet_editor_services_%s.zip"):format(version)
            end),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
