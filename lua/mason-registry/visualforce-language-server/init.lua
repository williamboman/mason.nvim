local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local github_client = require "mason-core.managers.github.client"
local Optional = require "mason-core.optional"
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
        local repo = "forcedotcom/salesforcedx-vscode"

        -- See https://github.com/forcedotcom/salesforcedx-vscode/issues/4184#issuecomment-1146052086
        ---@type GitHubRelease
        local release = github_client
            .fetch_releases(repo)
            :map(_.find_first(_.prop_satisfies(_.compose(_.gt(0), _.length), "assets")))
            :map(Optional.of_nilable)
            :get_or_throw() -- Result unwrap
            :or_else_throw "Failed to find release with assets." -- Optional unwrap

        github
            .unzip_release_file({
                version = Optional.of(release.tag_name),
                asset_file = _.compose(_.format "salesforcedx-vscode-visualforce-%s.vsix", _.gsub("^v", "")),
                repo = repo,
            })
            .with_receipt()

        ctx:link_bin(
            "visualforce-language-server",
            ctx:write_node_exec_wrapper(
                "visualforce-language-server",
                path.concat {
                    "extension",
                    "node_modules",
                    "@salesforce",
                    "salesforcedx-visualforce-language-server",
                    "out",
                    "src",
                    "visualforceServer.js",
                }
            )
        )
    end,
}
