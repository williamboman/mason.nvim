local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "ccls",
    desc = [[C/C++/ObjC language server supporting cross references, hierarchies, completion and semantic highlighting]],
    homepage = "https://github.com/MaskRay/ccls",
    languages = { Pkg.Lang.C, Pkg.Lang["C++"], Pkg.Lang["Obective-C"] },
    categories = { Pkg.Cat.LSP },
    ---@async
    install = function()
        platform.when {
            mac = require "mason-registry.ccls.mac",
            linux = require "mason-registry.ccls.linux",
        }
    end,
}
