local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "jq",
    desc = [[Command-line JSON processor]],
    homepage = "https://github.com/stedolan/jq",
    languages = { Pkg.Lang.JSON },
    categories = { Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "stedolan/jq",
                out_file = platform.is.win and "jq.exe" or "jq",
                asset_file = coalesce(
                    when(platform.is.mac, "jq-osx-amd64"),
                    when(platform.is.linux_x86, "jq-linux32"),
                    when(platform.is.linux_x64, "jq-linux64"),
                    when(platform.is.win_x86, "jq-win32.exe"),
                    when(platform.is.win_x64, "jq-win64.exe")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "jq" })
        ctx:link_bin("jq", platform.is.win and "jq.exe" or "jq")
    end,
}
