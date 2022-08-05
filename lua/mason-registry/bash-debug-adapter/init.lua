local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"
local path = require "mason-core.path"

return Pkg.new {
    name = "bash-debug-adapter",
    desc = [[Debug your bash scripts.]],
    homepage = "https://github.com/rogalmic/vscode-bash-debug",
    languages = { Pkg.Lang.JavaScript, Pkg.Lang.TypeScript },
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
            "bash-debug-adapter",
            ctx:write_node_exec_wrapper("bash-debug-adapter", path.concat { "out", "bashDebug.js" })
        )
    end,
}
