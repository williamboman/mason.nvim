local a = require "mason-core.async"
local _ = require "mason-core.functional"
local Pkg = require "mason-core.package"
local std = require "mason-core.managers.std"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "haskell-language-server",
    desc = [[Official Haskell Language Server implementation.]],
    homepage = "https://haskell-language-server.readthedocs.io/en/latest/",
    languages = { Pkg.Lang.Haskell },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local source = github.release_version { repo = "haskell/haskell-language-server" }
        source.with_receipt()

        std.ensure_executable("ghcup", { help_url = "https://www.haskell.org/ghcup/" })
        ctx:promote_cwd()
        ctx.spawn.ghcup { "install", "hls", source.release, "-i", ctx.cwd:get() }

        platform.when {
            unix = function()
                ctx:link_bin(
                    "haskell-language-server-wrapper",
                    path.concat { "bin", "haskell-language-server-wrapper" }
                )

                a.scheduler()
                for _, executable_abs_path in
                    ipairs(
                        vim.fn.glob(path.concat { ctx.cwd:get(), "bin", "haskell-language-server-[0-9]*" }, true, true)
                    )
                do
                    local executable = vim.fn.fnamemodify(executable_abs_path, ":t")
                    ctx:link_bin(executable, path.concat { "bin", executable })
                end
            end,
            win = function()
                ctx:link_bin("haskell-language-server-wrapper", "haskell-language-server-wrapper.exe")

                a.scheduler()
                for _, executable_abs_path in
                    ipairs(vim.fn.glob(path.concat { ctx.cwd:get(), "haskell-language-server-[0-9]*" }, true, true))
                do
                    local executable = vim.fn.fnamemodify(executable_abs_path, ":t:r")
                    ctx:link_bin(executable, ("%s.exe"):format(executable))
                end
            end,
        }
    end,
}
