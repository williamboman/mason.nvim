local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "svlangserver",
    desc = _.dedent [[
        A language server for systemverilog that has been tested to work with coc.nvim, VSCode, Sublime Text 4, emacs,
        and Neovim.
    ]],
    homepage = "https://github.com/imc-trading/svlangserver",
    languages = { Pkg.Lang.SystemVerilog },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@imc-trading/svlangserver", bin = { "svlangserver" } },
}
