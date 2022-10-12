local Pkg = require "mason-core.package"
local git = require "mason-core.managers.git"
local platform = require "mason-core.platform"
local path = require "mason-core.path"

return Pkg.new {
    name = "prisma-fmt",
    desc = [[Prisma ORM formatter.]],
    homepage = "https://github.com/prisma/prisma-engines/",
    languages = { Pkg.Lang["Prisma"] },
    categories = { Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        git.clone({ "https://github.com/prisma/prisma-engines/" }).with_receipt()
        ctx:chdir("prisma-fmt", function()
            ctx.spawn.cargo { "+nightly", "build", "--release" }
        end)
        ctx:link_bin(
            "prisma-fmt",
            path.concat { "target", "release", platform.is.win and "prisma-fmt.exe" or "prisma-fmt" }
        )
    end,
}
