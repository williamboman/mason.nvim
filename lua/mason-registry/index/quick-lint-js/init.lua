local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local std = require "mason-core.managers.std"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "quick-lint-js",
    desc = _.dedent [[
        Over 130× faster than ESLint, quick-lint-js gives you instant feedback as you code. Find bugs in your JavaScript
        before your finger leaves the keyboard. Lint any JavaScript file with no configuration.
    ]],
    homepage = "https://quick-lint-js.com/",
    languages = { Pkg.Lang.JavaScript },
    categories = { Pkg.Cat.LSP, Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "quick-lint/quick-lint-js"
        local release_file = assert(
            coalesce(
                when(platform.is.mac_x64, "macos.tar.gz"),
                when(platform.is.mac_arm64, "macos-aarch64.tar.gz"),
                when(platform.is.linux_x64, "linux.tar.gz"),
                when(platform.is.linux_arm64, "linux-aarch64.tar.gz"),
                when(platform.is.linux_arm, "linux-armhf.tar.gz"),
                when(platform.is.win_x64, "windows.zip"),
                when(platform.is.win_arm64, "windows-arm64.zip"),
                when(platform.is.win_arm, "windows-arm.zip")
            ),
            "Current platform is not supported."
        )

        local source = github.tag { repo = repo }
        source.with_receipt()

        local url = ("https://c.quick-lint-js.com/releases/%s/manual/%s"):format(source.tag, release_file)
        platform.when {
            unix = function()
                std.download_file(url, "archive.tar.gz")
                std.untar("archive.tar.gz", { strip_components = 1 })
            end,
            win = function()
                std.download_file(url, "archive.zip")
                std.unzip("archive.zip", ".")
            end,
        }
        ctx:link_bin("quick-lint-js", path.concat { "bin", platform.is.win and "quick-lint-js.exe" or "quick-lint-js" })
    end,
}
