local Optional = require "mason-core.optional"
local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local github_client = require "mason-core.managers.github.client"
local path = require "mason-core.path"

return Pkg.new {
    name = "bash-debug-adapter",
    desc = [[Bash shell debugger, based on bashdb.]],
    homepage = "https://github.com/rogalmic/vscode-bash-debug",
    languages = { Pkg.Lang.Bash },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "rogalmic/vscode-bash-debug"
        ---@type GitHubRelease
        local release = ctx.requested_version
            :map(function(version)
                return github_client.fetch_release(repo, version)
            end)
            :or_else_get(function()
                return github_client.fetch_latest_release(repo)
            end)
            :get_or_throw()

        local release_asset = _.find_first(_.prop_satisfies(_.matches "%.vsix$", "name"), release.assets)

        github
            .unzip_release_file({
                repo = repo,
                asset_file = release_asset.name,
                version = Optional.of(release.tag_name),
            })
            .with_receipt()

        ctx.fs:rmrf(path.concat { "extension", "images" })
        ctx:link_bin(
            "bash-debug-adapter",
            ctx:write_node_exec_wrapper("bash-debug-adapter", path.concat { "extension", "out", "bashDebug.js" })
        )
    end,
}
