--[[
Configuration:

-- You can use the Mason-generated shell execution wrapper:
require("lspconfig").drools_lsp.setup {
    capabilities = capabilities,
    on_attach = on_attach,
    cmd = { 'drools-lsp' },
}

-- or you can specify the path to the Mason-installed drools jar file (allowing you to also specify java settings):
local util = require "lspconfig.util"
local reg = require "mason-registry"
local jar = "drools-lsp-server-jar-with-dependencies.jar"
require("lspconfig").drools_lsp.setup {
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
        -- optional
        java = {
            bin = "/path/to/java",
            opts = { "-Xmx500m" },
        },
        -- required
        drools = {
            jar = util.path.join(reg.get_package("drools-lsp"):get_install_path(), jar),
            -- the above is *currently* equivalent to the below (but path below could change in the future)
            -- jar = vim.fn.stdpath "data" .. "/mason/packages/drools-lsp/" .. jar,
        },
    },
}

-- or you can use any of the other configuration options listed here:
https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#drools_lsp
--]]

local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local Optional = require "mason-core.optional"
local path = require "mason-core.path"

local name = "drools-lsp"
local repo = "kiegroup/" .. name
local file = name .. "-server-jar-with-dependencies.jar"

return Pkg.new {
    name = name,
    desc = [[An implementation of a language server for the Drools Rule Language.]],
    homepage = "https://github.com/" .. repo,
    languages = { Pkg.Lang.Drools },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .download_release_file({
                repo = repo,
                version = Optional.of "latest",
                asset_file = file,
                out_file = file,
            })
            .with_receipt()
        ctx:link_bin(
            name,
            ctx:write_shell_exec_wrapper(
                name,
                ("java -cp %q org.drools.lsp.server.Main"):format(path.concat { ctx.package:get_install_path(), file })
            )
        )
    end,
}
