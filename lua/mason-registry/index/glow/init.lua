local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "glow",
    desc = [[Render markdown on the CLI, with pizzazz]],
    homepage = "https://github.com/charmbracelet/glow",
    languages = { Pkg.Lang.Markdown },
    categories = {},
    install = function(ctx)
        ---@param template_string string
        local function release_file(template_string)
            return _.compose(_.format(template_string), _.gsub("^v", ""))
        end
        local asset_file = coalesce(
            when(platform.is.mac_arm64, release_file "glow_%s_Darwin_arm64.tar.gz"),
            when(platform.is.mac_x64, release_file "glow_%s_Darwin_x86_64.tar.gz"),
            when(platform.is.linux_x64_openbsd, release_file "glow_%s_openbsd_x86_64.tar.gz"),
            when(platform.is.linux_arm64_openbsd, release_file "glow_%s_openbsd_arm64.tar.gz"),
            when(platform.is.linux_arm64, release_file "glow_%s_linux_arm64.tar.gz"),
            when(platform.is.linux_x64, release_file "glow_%s_linux_x86_64.tar.gz"),
            when(platform.is.win_x86, release_file "glow_%s_Windows_i386.zip"),
            when(platform.is.win_x64, release_file "glow_%s_Windows_x86_64.zip")
        )
        local source = platform.when {
            unix = function()
                return github.untargz_release_file {
                    repo = "charmbracelet/glow",
                    asset_file = asset_file,
                }
            end,
            win = function()
                return github.unzip_release_file {
                    repo = "charmbracelet/glow",
                    asset_file = asset_file,
                }
            end,
        }
        source.with_receipt()
        ctx:link_bin("glow", platform.is.win and "glow.exe" or "glow")
    end,
}
