local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local fs = require "mason-core.fs"
local git = require "mason-core.managers.git"
local path = require "mason-core.path"

return Pkg.new {
    name = "smithy-language-server",
    desc = "A Language Server Protocol implementation for the Smithy IDL.",
    homepage = "https://github.com/awslabs/smithy-language-server",
    languages = { Pkg.Lang.Smithy },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        git.clone({ "https://github.com/awslabs/smithy-language-server" }).with_receipt()
        ctx:promote_cwd()
        ctx.spawn.gradlew {
            "build",
            with_paths = { ctx.cwd:get() },
        }

        local version = _.trim(ctx.fs:read_file "VERSION")

        ctx:link_bin(
            "smithy-language-server",
            ctx:write_shell_exec_wrapper(
                "smithy-language-server",
                ("java -jar %q"):format(path.concat {
                    ctx.package:get_install_path(),
                    "build",
                    "libs",
                    ("smithy-language-server-%s.jar"):format(version),
                })
            )
        )
    end,
}
