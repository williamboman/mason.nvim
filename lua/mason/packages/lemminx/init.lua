local Pkg = require "mason.core.package"
local _ = require "mason.core.functional"
local platform = require "mason.core.platform"
local std = require "mason.core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "lemminx",
    desc = [[XML Language Server]],
    homepage = "https://github.com/eclipse/lemminx",
    languages = { Pkg.Lang.XML },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local unzipped_file = assert(
            coalesce(
                when(platform.is.mac, "lemminx-osx-x86_64"),
                when(platform.is.linux_x64, "lemminx-linux"),
                when(platform.is.win, "lemminx-win32")
            ),
            ("Your operating system or architecture (%q) is not yet supported."):format(platform.arch)
        )

        std.download_file(
            ("https://download.jboss.org/jbosstools/vscode/snapshots/lemminx-binary/%s/%s.zip"):format(
                ctx.requested_version:or_else "0.19.2-655", -- TODO: resolve latest version dynamically
                unzipped_file
            ),
            "lemminx.zip"
        )
        std.unzip("lemminx.zip", ".")
        ctx.fs:rename(
            platform.is.win and ("%s.exe"):format(unzipped_file) or unzipped_file,
            platform.is.win and "lemminx.exe" or "lemminx"
        )
        ctx.receipt:with_primary_source(ctx.receipt.unmanaged)
        ctx:link_bin("lemminx", platform.is.win and "lemminx.exe" or "lemminx")
    end,
}
