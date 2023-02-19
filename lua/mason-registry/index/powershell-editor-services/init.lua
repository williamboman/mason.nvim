local Pkg = require "mason-core.package"
local std = require "mason-core.managers.std"
local github = require "mason-core.managers.github"

return Pkg.new {
    name = "powershell-editor-services",
    desc = [[A common platform for PowerShell development support in any editor or application!]],
    homepage = "https://github.com/PowerShell/PowerShellEditorServices",
    languages = { Pkg.Lang.PowerShell },
    categories = { Pkg.Cat.LSP },
    ---@async
    install = function()
        std.ensure_executable("pwsh", { help_url = "https://github.com/PowerShell/PowerShell#get-powershell" })
        github
            .unzip_release_file({
                repo = "PowerShell/PowerShellEditorServices",
                asset_file = "PowerShellEditorServices.zip",
            })
            .with_receipt()
    end,
}
