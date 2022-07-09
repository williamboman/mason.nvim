local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "shfmt",
    desc = [[A shell formatter (sh/bash/mksh)]],
    homepage = "https://github.com/mvdan/sh",
    languages = { Pkg.Lang.Bash, Pkg.Lang.Mksh, Pkg.Lang.Shell },
    categories = { Pkg.Cat.Formatter },
    install = go.packages { "mvdan.cc/sh/v3/cmd/shfmt", bin = { "shfmt" } },
}
