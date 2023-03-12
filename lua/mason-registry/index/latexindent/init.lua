local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "latexindent",
    desc = _.dedent [[
        latexindent.pl is a perl script to beautify/tidy/format/indent (add horizontal leading space to) code within
        environments, commands, after headings and within special code blocks.
    ]],
    homepage = "https://github.com/cmhughes/latexindent.pl",
    languages = { Pkg.Lang.LaTeX },
    categories = { Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "cmhughes/latexindent.pl",
                out_file = platform.is.win and "latexindent.exe" or "latexindent",
                asset_file = coalesce(
                    when(platform.is.mac_x64, "latexindent-macos"),
                    when(platform.is.mac_arm64, "latexindent-macos"),
                    when(platform.is.linux_x64_gnu, "latexindent-linux"),
                    when(platform.is.win_x64, "latexindent.exe")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "latexindent" })
        ctx:link_bin("latexindent", platform.is.win and "latexindent.exe" or "latexindent")
    end,
}
