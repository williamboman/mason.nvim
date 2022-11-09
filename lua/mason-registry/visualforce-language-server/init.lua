local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"
local path = require "mason-core.path"

return Pkg.new {
    name = "visualforce-language-server",
    desc = [[Visualforce language server]],
    homepage = "https://github.com/forcedotcom/salesforcedx-vscode",
    languages = { Pkg.Lang.Visualforce },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                asset_file = _.compose(_.format "salesforcedx-vscode-visualforce-%s.vsix", _.gsub("^v", "")),
                repo = "forcedotcom/salesforcedx-vscode",
            })
            .with_receipt()

        ctx:link_bin(
            "visualforce-language-server",
            ctx:write_node_exec_wrapper(
                "visualforce-language-server",
                path.concat {
                    "extension",
                    "dist",
                    "visualforceServer.js",
                }
            )
        )
    end,
}
