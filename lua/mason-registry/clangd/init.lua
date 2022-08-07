local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "clangd",
    desc = _.dedent [[
        clangd understands your C++ code and adds smart features to your editor: code completion, compile errors,
        go-to-definition and more.
    ]],
    homepage = "https://clangd.llvm.org",
    languages = { Pkg.Lang.C, Pkg.Lang["C++"] },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local source = github.unzip_release_file {
            repo = "clangd/clangd",
            asset_file = function(release)
                local target = coalesce(
                    when(platform.is.mac, "clangd-mac-%s.zip"),
                    when(platform.is.linux_x64, "clangd-linux-%s.zip"),
                    when(platform.is.win_x64, "clangd-windows-%s.zip")
                )
                return target and target:format(release)
            end,
        }
        source.with_receipt()
        ctx.fs:rename(("clangd_%s"):format(source.release), "clangd")
        ctx:link_bin(
            "clangd",
            path.concat {
                "clangd",
                "bin",
                platform.is.win and "clangd.exe" or "clangd",
            }
        )
    end,
}
