local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "puppet-editor-services",
    desc = [[Puppet Language Server for editors]],
    homepage = "https://github.com/puppetlabs/puppet-editor-services",
    languages = { Pkg.Lang.Puppet },
    categories = { Pkg.Cat.LSP, Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        assert(platform.is.unix, "puppet-editor-services only supports UNIX environments.")
        github
            .unzip_release_file({
                repo = "puppetlabs/puppet-editor-services",
                asset_file = function(version)
                    return ("puppet_editor_services_%s.zip"):format(version)
                end,
            })
            .with_receipt()
        ctx:link_bin("puppet-languageserver", "puppet-languageserver")
        ctx:link_bin("puppet-debugserver", "puppet-debugserver")
    end,
}
