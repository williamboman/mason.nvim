local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local _ = require "mason-core.functional"
local path = require "mason-core.path"

return Pkg.new {
    name = "go-debug-adapter",
    desc = [[Go debug adapter sourced from the VSCode Go extension.]],
    homepage = "https://github.com/golang/vscode-go",
    languages = { Pkg.Lang.Go },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "golang/vscode-go",
                asset_file = _.compose(_.format "go-%s.vsix", _.gsub("^v", "")),
            })
            .with_receipt()

        ctx:link_bin(
            "go-debug-adapter",
            ctx:write_node_exec_wrapper("go-debug-adapter", path.concat { "extension", "dist", "debugAdapter.js" })
        )
    end,
}
