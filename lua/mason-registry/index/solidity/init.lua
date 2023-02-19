local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "solidity",
    desc = [[Solidity, the Smart Contract Programming Language]],
    homepage = "https://github.com/ethereum/solidity",
    categories = { Pkg.Cat.Compiler, Pkg.Cat.LSP },
    languages = { Pkg.Lang.Solidity },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "ethereum/solidity",
                out_file = platform.is.win and "solc.exe" or "solc",
                asset_file = coalesce(
                    when(platform.is.mac, "solc-macos"),
                    when(platform.is.linux, "solc-static-linux"),
                    when(platform.is.win, "solc-windows.exe")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "solc" })
        ctx:link_bin("solc", platform.is.win and "solc.exe" or "solc")
    end,
}
