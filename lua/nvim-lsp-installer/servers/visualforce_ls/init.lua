local server = require "nvim-lsp-installer.server"
local github = require "nvim-lsp-installer.core.managers.github"
local github_client = require "nvim-lsp-installer.core.managers.github.client"
local Optional = require "nvim-lsp-installer.core.optional"
local path = require "nvim-lsp-installer.core.path"
local _ = require "nvim-lsp-installer.core.functional"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/forcedotcom/salesforcedx-vscode",
        languages = { "visualforce" },
        ---@async
        installer = function()
            local repo = "forcedotcom/salesforcedx-vscode"

            -- See https://github.com/forcedotcom/salesforcedx-vscode/issues/4184#issuecomment-1146052086
            ---@type GitHubRelease
            local release = github_client
                .fetch_releases(repo)
                :map(_.find_first(_.prop_satisfies(_.compose(_.gt(0), _.length), "assets")))
                :map(Optional.of_nilable)
                :get_or_throw() -- Result unwrap
                :or_else_throw "Failed to find release with assets." -- Optional unwrap

            github.unzip_release_file({
                version = Optional.of(release.tag_name),
                asset_file = _.compose(_.format "salesforcedx-vscode-visualforce-%s.vsix", _.gsub("^v", "")),
                repo = repo,
            }).with_receipt()
        end,
        default_options = {
            cmd = {
                "node",
                path.concat {
                    root_dir,
                    "extension",
                    "node_modules",
                    "@salesforce",
                    "salesforcedx-visualforce-language-server",
                    "out",
                    "src",
                    "visualforceServer.js",
                },
                "--stdio",
            },
        },
    }
end
