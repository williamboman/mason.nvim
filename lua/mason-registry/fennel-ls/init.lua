local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local git = require "mason-core.managers.git"

return Pkg.new {
    name = "fennel-ls",
    desc = [[Fennel language server]],
    languages = { Pkg.Lang.Fennel },
    categories = { Pkg.Cat.LSP },
    homepage = "https://sr.ht/~xerool/fennel-ls",
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        git.clone({ "https://git.sr.ht/~xerool/fennel-ls" }).with_receipt()
        ctx.spawn.make {}
    end,
}
