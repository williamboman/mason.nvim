local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"
local path = require "mason-core.path"

return Pkg.new {
    name = "java-test",
    desc = _.dedent [[
    Test Runner for Java. Intended to be used with
    [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls#vscode-java-test-installation).

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
        github
            .unzip_release_file({
                repo = "microsoft/vscode-java-test",
                asset_file = _.compose(_.format "vscjava.vscode-java-test-%s.vsix", _.gsub("^v", "")),
            })
            .with_receipt()

        ctx.fs:rmrf(path.concat { "extension", "resources" })
        ctx.fs:rmrf(path.concat { "extension", "dist" })

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
