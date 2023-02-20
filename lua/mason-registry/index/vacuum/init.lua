local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "vacuum",
    desc = _.dedent [[
        vacuum is the worlds fastest OpenAPI 3, OpenAPI 2 / Swagger linter and quality analysis tool.
        Built in go, it tears through API specs faster than you can think.
        vacuum is compatible with Spectral rulesets and generates compatible reports.
    ]],
    homepage = "https://github.com/daveshanley/vacuum",
    languages = { Pkg.Lang.OpenAPI },
    categories = { Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        ---@param template string
        local function release_file(template)
            return _.compose(_.format(template), _.strip_prefix "v")
        end

        github
            .untargz_release_file({
                repo = "daveshanley/vacuum",
                asset_file = coalesce(
                    when(platform.is.darwin_arm64, release_file "vacuum_%s_darwin_arm64.tar.gz"),
                    when(platform.is.darwin_x64, release_file "vacuum_%s_darwin_x86_64.tar.gz"),
                    when(platform.is.linux_arm64, release_file "vacuum_%s_linux_arm64.tar.gz"),
                    when(platform.is.linux_x64, release_file "vacuum_%s_linux_x86_64.tar.gz"),
                    when(platform.is.linux_x86, release_file "vacuum_%s_linux_i386.tar.gz"),
                    when(platform.is.win_arm64, release_file "vacuum_%s_windows_arm64.tar.gz"),
                    when(platform.is.win_x64, release_file "vacuum_%s_windows_x86_64.tar.gz"),
                    when(platform.is.win_x86, release_file "vacuum_%s_windows_i386.tar.gz")
                ),
            })
            .with_receipt()
        ctx:link_bin("vacuum", platform.is.win and "vacuum.exe" or "vacuum")
    end,
}
