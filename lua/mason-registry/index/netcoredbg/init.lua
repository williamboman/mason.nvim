local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"
local path = require "mason-core.path"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "netcoredbg",
    desc = [[NetCoreDbg is a managed code debugger with MI interface for CoreCLR.]],
    homepage = "https://github.com/Samsung/netcoredbg",
    languages = { Pkg.Lang[".NET"], Pkg.Lang["C#"], Pkg.Lang["F#"] },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        platform.when {
            unix = function()
                github
                    .untargz_release_file({
                        repo = "Samsung/netcoredbg",
                        asset_file = _.coalesce(
                            _.when(platform.is.mac, "netcoredbg-osx-amd64.tar.gz"),
                            _.when(platform.is.linux_x64, "netcoredbg-linux-amd64.tar.gz"),
                            _.when(platform.is.linux_arm64, "netcoredbg-linux-arm64.tar.gz")
                        ),
                    })
                    .with_receipt()
                ctx.fs:rename("netcoredbg", "build")
                ctx:link_bin("netcoredbg", ctx:write_exec_wrapper("netcoredbg", path.concat { "build", "netcoredbg" }))
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = "Samsung/netcoredbg",
                        asset_file = _.when(platform.is.win_x64, "netcoredbg-win64.zip"),
                    })
                    .with_receipt()
                ctx:link_bin("netcoredbg", path.concat { "netcoredbg", "netcoredbg.exe" })
            end,
        }
    end,
}
