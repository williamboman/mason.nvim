local Pkg = require "mason.core.package"
local github = require "mason.core.managers.github"
local _ = require "mason.core.functional"
local path = require "mason.core.path"

return Pkg.new {
    name = "dart-debug-adapter",
    desc = [[Dart debug adapter sourced from the VSCode Dart extension.]],
    homepage = "https://github.com/Dart-Code/Dart-Code",
    languages = { Pkg.Lang.Dart, Pkg.Lang.Flutter },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "Dart-Code/Dart-Code",
                asset_file = _.compose(_.format "dart-code-%s.vsix", _.gsub("^v", "")),
            })
            .with_receipt()
        ctx.fs:rmrf(path.concat { "extension", "media" }) -- unnecessary media assets
        ctx:write_node_exec_wrapper("dart-debug-adapter", path.concat { "extension", "out", "dist", "debug.js" })
        ctx:link_bin("dart-debug-adapter", "dart-debug-adapter")
    end,
}
