local Pkg = require "mason-core.package"
local luarocks = require "mason-core.managers.luarocks"

return Pkg.new {
    name = "teal-language-server",
    desc = [[A language server for Teal, a typed dialect of Lua]],
    homepage = "https://github.com/teal-language/teal-language-server",
    languages = { Pkg.Lang.Teal },
    categories = { Pkg.Cat.LSP },
    install = luarocks.package("teal-language-server", {
        dev = true,
        bin = { "teal-language-server" },
    }),
}
