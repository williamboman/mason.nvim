local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "buf",
    desc = _.dedent [[
        The Buf CLI is a one stop shop for your local Protocol Buffers needs. It comes with a linter that enforces good
        API designs, a breaking change detector, a generator, a formatter that formats your Protobuf files in accordance
        with industry standards. It also helps you manage your Protobuf assets on the Buf Schema Registry.
    ]],
    homepage = "https://buf.build",
    languages = { Pkg.Lang.Protobuf },
    categories = { Pkg.Cat.Linter, Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "bufbuild/buf",
                out_file = platform.is.win and "buf.exe" or "buf",
                asset_file = coalesce(
                    when(platform.is.mac_x64, "buf-Darwin-x86_64"),
                    when(platform.is.mac_arm64, "buf-Darwin-arm64"),
                    when(platform.is.linux_x64, "buf-Linux-x86_64"),
                    when(platform.is.linux_arm64, "buf-Linux-aarch64"),
                    when(platform.is.win_arm64, "buf-Windows-arm64.exe"),
                    when(platform.is.win_x64, "buf-Windows-x86_64.exe")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "buf" })
        ctx:link_bin("buf", platform.is.win and "buf.exe" or "buf")
    end,
}
