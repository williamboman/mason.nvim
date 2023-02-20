local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local path = require "mason-core.path"

return Pkg.new {
    name = "codelldb",
    desc = [[A native debugger based on LLDB]],
    homepage = "https://github.com/vadimcn/vscode-lldb",
    languages = { Pkg.Lang.C, Pkg.Lang["C++"], Pkg.Lang.Rust },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "vadimcn/vscode-lldb",
                asset_file = _.coalesce(
                    _.when(platform.is.mac_x64, "codelldb-x86_64-darwin.vsix"),
                    _.when(platform.is.mac_arm64, "codelldb-aarch64-darwin.vsix"),
                    _.when(platform.is.linux_x64_gnu, "codelldb-x86_64-linux.vsix"),
                    _.when(platform.is.linux_arm64_gnu, "codelldb-aarch64-linux.vsix"),
                    _.when(platform.is.linux_arm_gnu, "codelldb-arm-linux.vsix"),
                    _.when(platform.is.win_x64, "codelldb-x86_64-windows.vsix")
                ),
            })
            .with_receipt()
        platform.when {
            unix = function()
                ctx:link_bin(
                    "codelldb",
                    ctx:write_exec_wrapper("codelldb", path.concat { "extension", "adapter", "codelldb" })
                )
            end,
            win = function()
                ctx:link_bin("codelldb", path.concat { "extension", "adapter", "codelldb.exe" })
            end,
        }
    end,
}
