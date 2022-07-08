local Pkg = require "mason-core.package"

return Pkg.new {
    name = "dummy",
    desc = [[This is a dummy package.]],
    categories = { Pkg.Cat.LSP },
    languages = { Pkg.Lang.DummyLang },
    homepage = "https://example.com",
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        ctx.receipt:with_primary_source { type = "dummy" }
    end,
}
