local Pkg = require "mason-core.package"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "terraform-docs",
    desc = [[Generate documentation from Terraform modules in various output formats]],
    homepage = "https://terraform-docs.io",
    categories = { Pkg.Cat.Formatter },
    languages = { Pkg.Lang.Terraform },
    install = go.packages { "github.com/terraform-docs/terraform-docs", bin = { "terraform-docs" } },
}
