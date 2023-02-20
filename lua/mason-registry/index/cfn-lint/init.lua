local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "cfn-lint",
    desc = _.dedent [[
        CloudFormation Linter. Validate AWS CloudFormation YAML/JSON templates against the AWS CloudFormation Resource
        Specification and additional checks. Includes checking valid values for resource properties and best practices.
    ]],
    homepage = "https://github.com/aws-cloudformation/cfn-lint",
    languages = { Pkg.Lang.YAML, Pkg.Lang.JSON },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "cfn-lint", bin = { "cfn-lint" } },
}
