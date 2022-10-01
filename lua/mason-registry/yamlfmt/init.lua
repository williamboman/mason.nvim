local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "yamlfmt",
    desc = [[yamlfmt is an extensible command line tool or library to format yaml files.]],
    homepage = "https://github.com/google/yamlfmt",
    categories = { Pkg.Cat.Formatter },
    languages = { Pkg.Lang.YAML },
    install = function(ctx)
        ---@param template_string string
        local function release_file(template_string)
            return _.compose(_.format(template_string), _.gsub("^v", ""))
        end

        github
            .untargz_release_file({
                repo = "google/yamlfmt",
                asset_file = coalesce(
                    when(platform.is.mac_arm64, release_file "yamlfmt_%s_Darwin_arm64.tar.gz"),
                    when(platform.is.mac_x64, release_file "yamlfmt_%s_Darwin_x86_64.tar.gz"),
                    when(platform.is.linux_arm64, release_file "yamlfmt_%s_Linux_arm64.tar.gz"),
                    when(platform.is.linux_x64, release_file "yamlfmt_%s_Linux_x86_64.tar.gz"),
                    when(platform.is.win_x86, release_file "yamlfmt_%s_Windows_i386.tar.gz"),
                    when(platform.is.win_x64, release_file "yamlfmt_%s_Windows_x86_64.tar.gz")
                ),
            })
            .with_receipt()
        ctx:link_bin("yamlfmt", platform.is.win and "yamlfmt.exe" or "yamlfmt")
    end,
}
