local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "arduino-language-server",
    desc = [[An Arduino Language Server based on Clangd to Arduino code autocompletion]],
    homepage = "https://github.com/arduino/arduino-language-server",
    languages = { Pkg.Lang.Arduino },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local opts = {
            repo = "arduino/arduino-language-server",
            asset_file = function(release)
                local target = coalesce(
                    when(platform.is.mac, "arduino-language-server_%s_macOS_64bit.tar.gz"),
                    when(platform.is.linux_x64, "arduino-language-server_%s_Linux_64bit.tar.gz"),
                    when(platform.is.linux_x86, "arduino-language-server_%s_Linux_32bit.tar.gz"),
                    when(platform.is.linux_arm64, "arduino-language-server_%s_Linux_ARM64.tar.gz"),
                    when(platform.is.win_x64, "arduino-language-server_%s_Windows_64bit.zip"),
                    when(platform.is.win_x86, "arduino-language-server_%s_Windows_32bit.zip")
                )

                return target and target:format(release)
            end,
        }

        platform.when {
            unix = function()
                github.untargz_release_file(opts).with_receipt()
                ctx:link_bin("arduino-language-server", "arduino-language-server")
            end,
            win = function()
                github.unzip_release_file(opts).with_receipt()
                ctx:link_bin("arduino-language-server", "arduino-language-server.exe")
            end,
        }
    end,
}
