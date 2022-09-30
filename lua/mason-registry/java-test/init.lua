-- https://github.com/mfussenegger/nvim-jdtls#vscode-java-test-installation
-- use vsix because building takes a while
local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local github_client = require "mason-core.managers.github.client"
local _ = require "mason-core.functional"
local path = require "mason-core.path"
local Optional = require "mason-core.optional"

return Pkg.new {
    name = "java-test",
    desc = _.dedent [[
    Test Runner for Java. Intended to be used with [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls#vscode-java-test-installation).

    Enables support for the following test frameworks:

    - JUnit 4 (v4.8.0+)
    - JUnit 5 (v5.1.0+)
    - TestNG (v6.8.0+)
    ]],
    homepage = "https://github.com/microsoft/vscode-java-test",
    languages = { Pkg.Lang.Java },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "microsoft/vscode-java-test"
        ---@type GitHubRelease
        local release = ctx.requested_version
            :map(function(version)
                return github_client.fetch_release(repo, version)
            end)
            :or_else_get(function()
                return github_client.fetch_latest_release(repo)
            end)
            :get_or_throw()

        ---@type GitHubReleaseAsset
        local release_asset = _.find_first(_.prop_satisfies(_.matches "%.vsix$", "name"), release.assets)

        github
            .unzip_release_file({
                repo = repo,
                asset_file = release_asset.name,
                version = Optional.of(release.tag_name),
            })
            .with_receipt()

        ctx.fs:rmrf(path.concat { "extension", "resources" })

        -- not necessary, raises the following error
        --[[
            Failed to load extension bundles
            Failed to get bundleInfo for bundle from com.microsoft.java.test.runner-jar-with-dependencies.jar
        ]]
        ctx.fs:rmrf(path.concat {
            "extension",
            "server",
            "com.microsoft.java.test.runner-jar-with-dependencies.jar",
        })
    end,
}
