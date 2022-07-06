local Pkg = require "mason.core.package"
local npm = require "mason.core.managers.npm"

return Pkg.new {
    name = "perlnavigator",
    desc = [[Perl Language Server that includes perl critic and code navigation]],
    homepage = "https://github.com/bscan/PerlNavigator",
    languages = { Pkg.Lang.Perl },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "perlnavigator-server" },
}
