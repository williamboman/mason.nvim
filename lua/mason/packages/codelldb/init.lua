local Pkg = require "mason.core.package"
local github = require "mason.core.managers.github"
local _ = require "mason.core.functional"
local platform = require "mason.core.platform"
local path = require "mason.core.path"

return Pkg.new {
    name = "codelldb",
    desc = [[Official repository for the Microsoft C/C++ extension for VS Code.]],
    homepage = "https://github.com/microsoft/vscode-cpptools",
    languages = { Pkg.Lang.C, Pkg.Lang["C++"], Pkg.Lang.Rust },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github.unzip_release_file({
            repo = "vadimcn/vscode-lldb",
            asset_file = _.coalesce(
                _.when(platform.is.mac_x64, "codelldb-x86_64-darwin.vsix"),
                _.when(platform.is.mac_arm64, "codelldb-aarch64-darwin.vsix"),
                _.when(platform.is.linux_x64, "codelldb-x86_64-linux.vsix"),
                _.when(platform.is.linux_arm64, "codelldb-aarch64-linux.vsix"),
                _.when(platform.is.linux_arm, "codelldb-arm-linux.vsix"),
                _.when(platform.is.win_x64, "codelldb-x86_64-windows.vsix")
            ),
        }).with_receipt()
        ctx:link_bin(
            "codelldb",
            path.concat { "extension", "adapter", platform.is.win and "codelldb.exe" or "codelldb" }
        )
    end,
}
