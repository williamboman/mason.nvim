local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "golines",
    desc = [[A golang formatter that fixes long lines]],
    homepage = "https://github.com/segmentio/golines",
    categories = { Pkg.Cat.Formatter },
    languages = { Pkg.Lang.Go },
    install = go.packages { "github.com/segmentio/golines", bin = { "golines" } },
}
