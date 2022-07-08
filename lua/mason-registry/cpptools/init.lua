local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local path = require "mason-core.path"

return Pkg.new {
    name = "cpptools",
    desc = [[Official repository for the Microsoft C/C++ extension for VS Code.]],
    homepage = "https://github.com/microsoft/vscode-cpptools",
    languages = { Pkg.Lang.C, Pkg.Lang["C++"], Pkg.Lang.Rust },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "microsoft/vscode-cpptools",
                asset_file = _.coalesce(
                    _.when(platform.is.mac_x64, "cpptools-osx.vsix"),
                    _.when(platform.is.mac_arm64, "cpptools-osx-arm64.vsix"),
                    _.when(platform.is.linux_x64, "cpptools-linux.vsix"),
                    _.when(platform.is.linux_arm64, "cpptools-linux-aarch64.vsix"),
                    _.when(platform.is.linux_arm, "cpptools-linux-armhf.vsix"),
                    _.when(platform.is.win_x64, "cpptools-win64.vsix"),
                    _.when(platform.is.win_arm64, "cpptools-win-arm64.vsix"),
                    _.when(platform.is.win_x86, "cpptools-win32.vsix")
                ),
            })
            .with_receipt()

        local debug_executable = path.concat {
            "extension",
            "debugAdapters",
            "bin",
            platform.is.win and "OpenDebugAD7.exe" or "OpenDebugAD7",
        }
        std.chmod("+x", debug_executable)
        ctx:link_bin("OpenDebugAD7", debug_executable)
    end,
}
