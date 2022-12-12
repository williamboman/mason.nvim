local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "semgrep",
    desc = "Semgrep is a fast, open-source, static analysis engine for finding bugs, detecting vulnerabilities in third-party dependencies, and enforcing code standards.",
    homepage = "https://github.com/returntocorp/semgrep",
    languages = {
        Pkg.Lang.Go,
        Pkg.Lang.Java,
        Pkg.Lang.Python,
        Pkg.Lang.Ruby,
        Pkg.Lang.TypeScript,
        Pkg.Lang.TypeScriptReact,
    },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "semgrep", bin = { "semgrep" } },
}
