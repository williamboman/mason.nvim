local Pkg = require "mason-core.package"
local git = require "mason-core.managers.git"
local platform = require "mason-core.platform"
local path = require "mason-core.path"

return Pkg.new {
    name = "metamath-zero-lsp",
    desc = [[An MM0/MM1 server written in Rust.]],
    homepage = "https://github.com/digama0/mm0",
    languages = { Pkg.Lang["Metamath Zero"] },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        git.clone({ "https://github.com/digama0/mm0" }).with_receipt()
        ctx:chdir("mm0-rs", function()
            ctx.spawn.cargo { "build", "--release" }
        end)
        ctx:link_bin(
            "mm0-rs",
            path.concat { "mm0-rs", "target", "release", platform.is.win and "mm0-rs.exe" or "mm0-rs" }
        )
    end,
}
