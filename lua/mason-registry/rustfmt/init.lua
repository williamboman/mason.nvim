local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "rustfmt",
    desc = [[A tool for formatting Rust code according to style guidelines]],
    homepage = "https://github.com/rust-lang/rustfmt",
    categories = { Pkg.Cat.Formatter },
    languages = { Pkg.Lang.Rust },
    install = function(ctx)
        ---@param template_string string
        local function release_file(template_string)
            return _.compose(_.format(template_string), _.gsub("^v", ""))
        end

        github
            .untargz_release_file({
                repo = "rust-lang/rustfmt",
                asset_file = coalesce(
                    when(platform.is.mac, release_file "rustfmt_macos-x86_64_%s.tar.gz"),
                    when(platform.is.linux_x64, release_file "rustfmt_linux-x86_64_%s.tar.gz"),
                    when(platform.is.win_x64, release_file "rustfmt_windows-x86_64-msvc_%s.tar.gz")
                ),
            })
            .with_receipt()
        ctx:link_bin("rustfmt", platform.is.win and "rustfmt.exe" or "rustfmt")
    end,
}
