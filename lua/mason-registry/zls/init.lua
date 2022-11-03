local Pkg = require "mason-core.package"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "zls",
    desc = [[Zig LSP implementation + Zig Language Server]],
    homepage = "https://github.com/zigtools/zls",
    languages = { Pkg.Lang.Zig },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local asset_file = coalesce(
            when(platform.is.mac_arm64, "aarch64-macos.tar.zst"),
            when(platform.is.mac_x64, "x86_64-macos.tar.zst"),
            when(platform.is.linux_x64, "x86_64-linux.tar.zst"),
            when(platform.is.linux_x86, "i386-linux.tar.zst"),
            when(platform.is.win_x64, "i386-windows.tar.zst"),
            when(platform.is.win_x64, "x86_64-windows.tar.zst")
        )
        github
            .untarzst_release_file({
                repo = "zigtools/zls",
                asset_file = asset_file,
            })
            .with_receipt()
        std.chmod("+x", { path.concat { "bin", "zls" } })
        ctx:link_bin("zls", path.concat { "bin", platform.is.win and "zls.exe" or "zls" })
    end,
}
