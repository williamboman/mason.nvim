local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "blackd-client",
    desc = [[Tiny HTTP client for the Black (blackd) Python code formatter]],
    homepage = "https://github.com/disrupted/blackd-client",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "disrupted/blackd-client",
                asset_file = coalesce(
                    when(platform.is.mac, "blackd-client_macos"),
                    when(platform.is.linux_x64_gnu, "blackd-client_linux")
                ),
                out_file = "blackd-client",
            })
            .with_receipt()
        std.chmod("+x", { "blackd-client" })
        ctx:link_bin("blackd-client", "blackd-client")
    end,
}
