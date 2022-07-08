local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "gomodifytags",
    desc = [[Go tool to modify/update field tags in structs]],
    homepage = "https://github.com/fatih/gomodifytags",
    categories = {},
    languages = { Pkg.Lang.Go },
    install = go.packages { "github.com/fatih/gomodifytags", bin = { "gomodifytags" } },
}
