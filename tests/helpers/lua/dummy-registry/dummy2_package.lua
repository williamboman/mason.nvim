local Pkg = require "mason-core.package"

return Pkg.new {
    schema = "registry+v1",
    name = "dummy2",
    description = [[This is a dummy2 package.]],
    homepage = "https://example.com",
    licenses = { Pkg.License.MIT },
    languages = { Pkg.Lang.Dummy2Lang },
    categories = { Pkg.Cat.LSP },
    source = {
        id = "pkg:mason/dummy2@1.0.0",
        ---@async
        ---@param ctx InstallContext
        install = function(ctx) end,
    },
}
