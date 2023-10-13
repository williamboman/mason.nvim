local Pkg = require "mason-core.package"

return Pkg:new {
    schema = "registry+v1",
    name = "dummy",
    description = [[This is a dummy package.]],
    homepage = "https://example.com",
    licenses = { Pkg.License.MIT },
    languages = { Pkg.Lang.DummyLang },
    categories = { Pkg.Cat.LSP },
    source = {
        id = "pkg:mason/dummy@1.0.0",
        ---@async
        ---@param ctx InstallContext
        install = function(ctx) end,
    },
}
