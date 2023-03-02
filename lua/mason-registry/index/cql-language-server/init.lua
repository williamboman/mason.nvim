local Pkg = require "mason-core.package"
local std = require "mason-core.managers.std"
local github = require "mason-core.managers.github"
local git = require "mason-core.managers.git"
local Optional = require "mason-core.optional"
local path = require "mason-core.path"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "cql-language-server",
    desc = [[A language server for Clinical Quality Language (CQL)]],
    homepage = "https://github.com/cqframework/cql-language-server",
    languages = { Pkg.Lang.cqlang },
    categories = { Pkg.Cat.LSP },
    --@async
    --@param ctx InstallContext
    install = function(ctx)
        std.ensure_executable("mvn", {
            help_url = "https://maven.apache.org/download.cgi",
        })

        local source = github.tag { repo = "cqframework/cql-language-server" }
        source.with_receipt()
        git.clone {
            "https://github.com/cqframework/cql-language-server",
            version = Optional.of(source.tag),
        }

        local version = _.gsub("^v", "", source.tag)

        ctx.spawn.mvn { "package", "-DskipTests" }

        ctx:link_bin(
            "cql-language-server",
            ctx:write_shell_exec_wrapper(
                "cql-language-server",
                ("java -jar %q"):format(path.concat {
                    ctx.package:get_install_path(),
                    "ls",
                    "service",
                    "target",
                    ("cql-ls-service-%s.jar"):format(version),
                })
            )
        )
    end,
}
