local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local installer = require "mason-core.installer"
local std = require "mason-core.managers.std"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

---@async
local function download_solang()
    local source = github
        .download_release_file({
            repo = "hyperledger-labs/solang",
            out_file = platform.is.win and "solang.exe" or "solang",
            asset_file = coalesce(
                when(platform.is.mac_x64, "solang-mac-intel"),
                when(platform.is.mac_arm64, "solang-mac-arm"),
                when(platform.is.linux_arm64, "solang-linux-arm64"),
                when(platform.is.linux_x64, "solang-linux-x86-64"),
                when(platform.is.win_x64, "solang.exe")
            ),
        })
        .with_receipt()
    std.chmod("+x", { "solang" })
    return source
end

---@async
---Solang needs a build of llvm with some extra patches.
local function download_llvm()
    local source = github.release_file {
        repo = "hyperledger-labs/solang",
        asset_file = coalesce(
            when(platform.is.mac_x64, "llvm13.0-mac-intel.tar.xz"),
            when(platform.is.mac_arm64, "llvm13.0-mac-arm.tar.xz"),
            when(platform.is.linux_x64, "llvm13.0-linux-x86-64.tar.xz"),
            when(platform.is.linux_arm64, "llvm13.0-linux-arm64.tar.xz"),
            when(platform.is.win_x64, "llvm13.0-win.zip")
        ),
    }
    if platform.is.win then
        std.download_file(source.download_url, "llvm.zip")
        std.unzip("llvm.zip", ".")
    else
        std.download_file(source.download_url, "llvm.tar.xz")
        std.untar "llvm.tar.xz"
    end
end

return Pkg.new {
    name = "solang",
    desc = [[Solidity Compiler for Solana, Substrate, and ewasm]],
    homepage = "https://solang.readthedocs.io/en/latest/",
    languages = { Pkg.Lang.Solidity },
    categories = { Pkg.Cat.LSP, Pkg.Cat.Compiler },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        installer.run_concurrently { download_solang, download_llvm }
        ctx:link_bin("solang", platform.is.win and "solang.exe" or "solang")
    end,
}
