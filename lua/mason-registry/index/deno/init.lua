local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "deno",
    desc = _.dedent [[
        Deno (/ˈdiːnoʊ/, pronounced dee-no) is a JavaScript, TypeScript, and WebAssembly runtime with secure defaults
        and a great developer experience.
    ]],
    homepage = "https://deno.land/manual/language_server/overview",
    languages = { Pkg.Lang.JavaScript, Pkg.Lang.TypeScript },
    categories = { Pkg.Cat.LSP, Pkg.Cat.Runtime },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "denoland/deno",
                asset_file = coalesce(
                    when(platform.is.mac_arm64, "deno-aarch64-apple-darwin.zip"),
                    when(platform.is.mac_x64, "deno-x86_64-apple-darwin.zip"),
                    when(platform.is.linux_x64, "deno-x86_64-unknown-linux-gnu.zip"),
                    when(platform.is.win_x64, "deno-x86_64-pc-windows-msvc.zip")
                ),
            })
            .with_receipt()
        ctx:link_bin("deno", platform.is.win and "deno.exe" or "deno")
    end,
}
