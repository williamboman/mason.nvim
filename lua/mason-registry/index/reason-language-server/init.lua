local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "reason-language-server",
    desc = [[A language server for reason, in reason]],
    homepage = "https://github.com/jaredly/reason-language-server",
    languages = { Pkg.Lang.Reason },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local archive_name = coalesce(
            when(platform.is.mac, "rls-macos"),
            when(platform.is.linux_x64, "rls-linux"),
            when(platform.is.win_x64, "rls-windows")
        )
        github
            .unzip_release_file({
                repo = "jaredly/reason-language-server",
                asset_file = ("%s.zip"):format(archive_name),
            })
            .with_receipt()
        ctx.fs:rename(archive_name, "reason")
        ctx:link_bin(
            "reason-language-server",
            path.concat {
                "reason",
                platform.is.win and "reason-language-server.exe" or "reason-language-server",
            }
        )
    end,
}
