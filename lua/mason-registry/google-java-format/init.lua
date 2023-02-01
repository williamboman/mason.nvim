local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

return Pkg.new {
    name = "google-java-format",
    desc = [[google-java-format is a program that reformats Java source code to comply with Google Java Style.]],
    homepage = "https://github.com/google/google-java-format",
    languages = { Pkg.Lang.Java },
    categories = { Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = "google/google-java-format",
                out_file = "google-java-format.jar",
                asset_file = function(release)
                    local version = release:gsub("^v", "")
                    return ("google-java-format-%s.jar"):format(version)
                end,
            })
            .with_receipt()

        ctx:link_bin(
            "google-java-format",
            ctx:write_shell_exec_wrapper(
                "google-java-format",
                ("java -jar %q"):format(path.concat { ctx.package:get_install_path(), "google-java-format.jar" })
            )
        )
    end,
}
