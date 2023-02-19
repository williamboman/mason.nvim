local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "cbfmt",
    desc = _.dedent [[
        A tool to format codeblocks inside markdown and org documents. It iterates over all codeblocks, and formats them
        with the tool(s) specified for the language of the block.
    ]],
    homepage = "https://github.com/lukas-reineke/cbfmt",
    languages = { Pkg.Lang.Markdown },
    categories = { Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local asset_file = coalesce(
            when(platform.is.mac, "cbfmt_macos-x86_64_%s.tar.gz"),
            when(platform.is.linux_x64_gnu, "cbfmt_linux-x86_64_%s.tar.gz"),
            when(platform.is.linux_x64_musl, "cbfmt_linux-x86_64-musl_%s.tar.gz"),
            when(platform.is.win_x64, "cbfmt_windows-x86_64-msvc_%s.zip")
        )

        local source = platform.when {
            unix = function()
                return github.untargz_release_file {
                    repo = "lukas-reineke/cbfmt",
                    asset_file = _.format(asset_file),
                }
            end,
            win = function()
                return github.unzip_release_file {
                    repo = "lukas-reineke/cbfmt",
                    asset_file = _.format(asset_file),
                }
            end,
        }
        source.with_receipt()
        local strip_extension = _.compose(_.gsub("%.zip$", ""), _.gsub("%.tar%.gz$", ""))
        ctx:link_bin(
            "cbfmt",
            path.concat { strip_extension(source.asset_file), platform.is.win and "cbfmt.exe" or "cbfmt" }
        )
    end,
}
