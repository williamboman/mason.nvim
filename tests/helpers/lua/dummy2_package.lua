local Pkg = require "mason-core.package"

return Pkg.new {
    name = "dummy2",
    desc = [[This is a dummy2 package.]],
    categories = { Pkg.Cat.LSP },
    languages = { Pkg.Lang.Dummy2Lang },
    homepage = "https://example.com",
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        ctx.receipt:with_primary_source { type = "dummy2" }
    end,
}
