local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "zk",
    desc = [[A plain text note-taking assistant]],
    homepage = "https://github.com/mickael-menu/zk",
    languages = { Pkg.Lang.Markdown },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "mickael-menu/zk"
        platform.when {
            mac = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.arch == "arm64", function(version)
                                return ("zk-%s-macos-arm64.zip"):format(version)
                            end),
                            when(platform.arch == "x64", function(version)
                                return ("zk-%s-macos-x86_64.zip"):format(version)
                            end)
                        ),
                    })
                    :with_receipt()
            end,
            linux = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.arch == "arm64", function(version)
                                return ("zk-%s-linux-arm64.tar.gz"):format(version)
                            end),
                            when(platform.arch == "x64", function(version)
                                return ("zk-%s-linux-amd64.tar.gz"):format(version)
                            end),
                            when(platform.arch == "x86", function(version)
                                return ("zk-%s-linux-i386.tar.gz"):format(version)
                            end)
                        ),
                    })
                    .with_receipt()
            end,
        }
        ctx:link_bin("zk", "zk")
    end,
}
