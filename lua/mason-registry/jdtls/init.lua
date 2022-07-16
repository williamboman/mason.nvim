local Pkg = require "mason-core.package"
local installer = require "mason-core.installer"
local _ = require "mason-core.functional"
local std = require "mason-core.managers.std"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local fetch = require "mason-core.fetch"

---@async
local function download_jdtls()
    local source = github.tag { repo = "eclipse/eclipse.jdt.ls" }
    source.with_receipt()

    local version = _.gsub("^v", "", source.tag)
    local response =
        fetch(("https://download.eclipse.org/jdtls/milestones/%s/latest.txt"):format(version)):get_or_throw "Failed to fetch latest release from eclipse.org."
    local release_file = _.head(_.split("\n", response))

    std.download_file(
        ("https://download.eclipse.org/jdtls/milestones/%s/%s"):format(version, release_file),
        "archive.tar.gz"
    )
    std.untar "archive.tar.gz"
end

---@async
local function download_lombok()
    std.download_file("https://projectlombok.org/downloads/lombok.jar", "lombok.jar")
end

return Pkg.new {
    name = "jdtls",
    desc = [[Java language server]],
    homepage = "https://github.com/eclipse/eclipse.jdt.ls",
    languages = { Pkg.Lang.Java },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        installer.run_concurrently { download_jdtls, download_lombok }
        platform.when {
            unix = function()
                ctx:link_bin("jdtls", path.concat { "bin", "jdtls" })
            end,
            win = function()
                ctx:link_bin(
                    "jdtls",
                    ctx:write_shell_exec_wrapper(
                        path.concat { "bin", "jdtls-win" },
                        ("python %q"):format(path.concat {
                            ctx.package:get_install_path(),
                            "bin",
                            "jdtls.py",
                        })
                    )
                )
            end,
        }
    end,
}
