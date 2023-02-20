local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "codeql",
    desc = _.dedent [[
        Discover vulnerabilities across a codebase with CodeQL, our industry-leading semantic code analysis engine.
        CodeQL lets you query code as though it were data. Write a query to find all variants of a vulnerability,
        eradicating it forever. Then share your query to help others do the same.
    ]],
    homepage = "https://github.com/github/codeql-cli-binaries",
    languages = { Pkg.Lang.CodeQL },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "github/codeql-cli-binaries",
                asset_file = coalesce(
                    when(platform.is.mac, "codeql-osx64.zip"),
                    when(platform.is.linux_x64, "codeql-linux64.zip"),
                    when(platform.is.win_x64, "codeql-win64.zip")
                ),
            })
            .with_receipt()
        ctx:link_bin("codeql", path.concat { "codeql", platform.is.win and "codeql.cmd" or "codeql" })
    end,
}
