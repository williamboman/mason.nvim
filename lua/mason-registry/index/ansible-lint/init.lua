local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "ansible-lint",
    desc = _.dedent [[
            Ansible Lint is a command-line tool for linting playbooks,
            roles and collections aimed toward any Ansible users.
    ]],
    homepage = "https://github.com/ansible/ansible-lint",
    languages = { Pkg.Lang.Ansible },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "ansible-lint", bin = { "ansible-lint" } },
}
