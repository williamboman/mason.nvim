local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"
local path = require "mason-core.path"

return Pkg.new {
    name = "php-debug-adapter",
    desc = [[PHP Debug Adapter 🐞⛔]],
    homepage = "https://github.com/xdebug/vscode-php-debug",
    languages = { Pkg.Lang.PHP },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "xdebug/vscode-php-debug",
                asset_file = _.compose(_.format "php-debug-%s.vsix", _.gsub("^v", "")),
            })
            .with_receipt()
        ctx.fs:rmrf(path.concat { "extension", "images" })
        ctx:link_bin(
            "php-debug-adapter",
            ctx:write_node_exec_wrapper("php-debug-adapter", path.concat { "extension", "out", "phpDebug.js" })
        )
    end,
}
