local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local Optional = require "mason-core.optional"
local path = require "mason-core.path"

return Pkg.new {
    name = "drools-lsp",
    desc = [[An implementation of a language server for the Drools Rule Language.]],
    homepage = "https://github.com/kiegroup/drools-lsp",
    languages = { Pkg.Lang.Drools },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local jar = "drools-lsp-server-jar-with-dependencies.jar"
        github
            .download_release_file({
                repo = "kiegroup/drools-lsp",
                version = Optional.of "latest",
                asset_file = jar,
                out_file = jar,
            })
            .with_receipt()
        ctx:link_bin(
            "drools-lsp",
            ctx:write_shell_exec_wrapper(
                "drools-lsp",
                ("java -jar %q"):format(path.concat { ctx.package:get_install_path(), jar })
            )
        )
    end,
}
