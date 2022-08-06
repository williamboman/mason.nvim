local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "cfn-lint",
    desc = [[CloudFormation Linter]],
    homepage = "https://github.com/aws-cloudformation/cfn-lint",
    languages = { Pkg.Lang.YAML, Pkg.Lang.JSON },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "cfn-lint", bin = { "cfn-lint" } },
}
