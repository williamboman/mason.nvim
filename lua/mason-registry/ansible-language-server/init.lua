local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "ansible-language-server",
    desc = [[Ansible Language Server]],
    homepage = "https://github.com/ansible/ansible-language-server",
    languages = { Pkg.Lang.Ansible },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "@ansible/ansible-language-server", bin = { "ansible-language-server" } },
}
