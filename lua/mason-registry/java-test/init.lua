local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"
local path = require "mason-core.path"

return Pkg.new {
    name = "java-test",
    desc = _.dedent [[
        The Test Runner for Java works with java-debug-adapter to provide the following features:
        - Run/Debug test cases
        - Customize test configurations
        - View test report
        - View tests in Test Explorer

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
                asset_file = _.format "vscjava.vscode-java-test-%s.vsix",
            })
            .with_receipt()

        ctx.fs:rmrf(path.concat { "extension", "resources" })
        ctx.fs:rmrf(path.concat { "extension", "dist" })
    end,
}
