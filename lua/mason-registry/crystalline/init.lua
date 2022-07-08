local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "crystalline",
    desc = [[A Language Server Protocol implementation for Crystal. 🔮]],
    homepage = "https://github.com/elbywan/crystalline",
    languages = { Pkg.Lang.Crystal },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .gunzip_release_file({
                repo = "elbywan/crystalline",
                asset_file = coalesce(
                    when(platform.is.mac_x64, "crystalline_x86_64-apple-darwin.gz"),
                    when(platform.is.linux_x64, "crystalline_x86_64-unknown-linux-gnu.gz")
                ),
                out_file = "crystalline",
            })
            .with_receipt()
        std.chmod("+x", { "crystalline" })
        ctx:link_bin("crystalline", "crystalline")
    end,
}
