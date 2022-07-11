local Pkg = require "mason-core.package"
local installer = require "mason-core.installer"
local eclipse = require "mason-core.clients.eclipse"
local std = require "mason-core.managers.std"
local path = require "mason-core.path"
local platform = require "mason-core.platform"

---@async
local function download_jdtls()
    local ctx = installer.context()
    local version = ctx.requested_version:or_else_get(function()
        return eclipse.fetch_latest_jdtls_version():get_or_throw()
    end)

    std.download_file(
        ("https://download.eclipse.org/jdtls/snapshots/jdt-language-server-%s.tar.gz"):format(version),
        "archive.tar.gz"
    )
    std.untar "archive.tar.gz"

    ctx.receipt:with_primary_source {
        type = "jdtls",
        version = version,
    }
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
