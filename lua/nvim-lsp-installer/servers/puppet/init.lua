local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.core.process"
local github = require "nvim-lsp-installer.core.managers.github"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/puppetlabs/puppet-editor-services",
        languages = { "puppet" },
        installer = function()
            github.unzip_release_file({
                repo = "puppetlabs/puppet-editor-services",
                asset_file = function(version)
                    return ("puppet_editor_services_%s.zip"):format(version)
                end,
            }).with_receipt()
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
