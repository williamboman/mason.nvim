local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "goimports-reviser",
    desc = _.dedent [[
        Tool for Golang to sort goimports by 3-4 groups: std, general, company (optional), and project dependencies.
        Also, formatting for your code will be prepared (so, you don't need to use gofmt or goimports separately).
        Use additional option -rm-unused to remove unused imports and -set-alias to rewrite import aliases for
        versioned packages.
    ]],
    homepage = "https://pkg.go.dev/github.com/incu6us/goimports-reviser",
    categories = { Pkg.Cat.Formatter },
    languages = { Pkg.Lang.Go },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local function format_release_file(template)
            return _.compose(_.format(template), _.gsub("^v", ""))
        end

        github
            .untargz_release_file({
                repo = "incu6us/goimports-reviser",
                asset_file = _.coalesce(
                    _.when(platform.is.mac_x64, format_release_file "goimports-reviser_%s_darwin_amd64.tar.gz"),
                    _.when(platform.is.mac_arm64, format_release_file "goimports-reviser_%s_darwin_arm64.tar.gz"),
                    _.when(platform.is.linux_x64, format_release_file "goimports-reviser_%s_linux_amd64.tar.gz"),
                    _.when(platform.is.win_x64, format_release_file "goimports-reviser_%s_windows_amd64.tar.gz")
                ),
            })
            .with_receipt()

        ctx:link_bin("goimports-reviser", platform.is.win and "goimports-reviser.exe" or "goimports-reviser")
    end,
}
