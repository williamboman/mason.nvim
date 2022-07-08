local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "marksman",
    desc = [[Markdown LSP server providing completion, cross-references, diagnostics, and more.]],
    homepage = "https://github.com/artempyanykh/marksman",
    languages = { Pkg.Lang.Markdown },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "artempyanykh/marksman",
                out_file = platform.is.win and "marksman.exe" or "marksman",
                asset_file = coalesce(
                    when(platform.is.mac, "marksman-macos"),
                    when(platform.is.linux_x64, "marksman-linux"),
                    when(platform.is.win_x64, "marksman.exe")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "marksman" })
        ctx:link_bin("marksman", platform.is.win and "marksman.exe" or "marksman")
    end,
}
