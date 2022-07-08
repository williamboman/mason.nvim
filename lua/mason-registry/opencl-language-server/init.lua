local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "opencl-language-server",
    desc = [[Provides an OpenCL kernel diagnostics]],
    homepage = "https://github.com/Galarius/opencl-language-server",
    languages = { Pkg.Lang.OpenCL },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        platform.when {
            unix = function()
                local asset_file = coalesce(
                    when(platform.is.mac, "opencl-language-server-darwin-x86_64.tar.gz"),
                    when(platform.is.linux_x64, "opencl-language-server-linux-x86_64.tar.gz")
                )
                github
                    .untargz_release_file({
                        repo = "Galarius/opencl-language-server",
                        asset_file = asset_file,
                    })
                    .with_receipt()
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = "Galarius/opencl-language-server",
                        asset_file = "opencl-language-server-win32-x86_64.zip",
                    })
                    .with_receipt()
            end,
        }
        ctx:link_bin(
            "opencl-language-server",
            platform.is.win and "opencl-language-server.exe" or "opencl-language-server"
        )
    end,
}
