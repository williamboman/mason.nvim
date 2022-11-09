local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "verible",
    desc = [[Verible is a suite of SystemVerilog developer tools, including a parser, style-linter, and formatter.]],
    homepage = "https://chipsalliance.github.io/verible/",
    languages = { Pkg.Lang.SystemVerilog },
    categories = { Pkg.Cat.LSP, Pkg.Cat.Linter, Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "chipsalliance/verible"
        platform.when {
            linux = function()
                local os_dist = platform.os_distribution()
                local source = github.untarxz_release_file {
                    repo = repo,
                    asset_file = coalesce(
                        when(
                            os_dist.id == "ubuntu" and platform.arch == "x64",
                            coalesce(
                                when(
                                    os_dist.version.major == 16,
                                    _.format "verible-%s-Ubuntu-16.04-xenial-x86_64.tar.gz"
                                ),
                                when(
                                    os_dist.version.major == 18,
                                    _.format "verible-%s-Ubuntu-18.04-bionic-x86_64.tar.gz"
                                ),
                                when(
                                    os_dist.version.major == 20,
                                    _.format "verible-%s-Ubuntu-20.04-focal-x86_64.tar.gz"
                                ),
                                when(
                                    os_dist.version.major == 22,
                                    _.format "verible-%s-Ubuntu-22.04-jammy-x86_64.tar.gz"
                                )
                            )
                        ),
                        when(
                            os_dist.id == "centos" and platform.arch == "x64",
                            coalesce(
                                when(
                                    os_dist.version.major == 7,
                                    _.format "verible-%s-CentOS-7.9.2009-Core-x86_64.tar.gz"
                                )
                            )
                        ),
                        when(platform.is.linux_x64_gnu, _.format "verible-%s-Ubuntu-20.04-focal-x86_64.tar.gz")
                    ),
                }
                source.with_receipt()
                ctx.fs:rename(("verible-%s"):format(source.release), "verible")
                for executable, rel_path in pairs {
                    ["git-verible-verilog-format.sh"] = { "verible", "bin", "git-verible-verilog-format.sh" },
                    ["verible-patch-tool"] = { "verible", "bin", "verible-patch-tool" },
                    ["verible-transform-interactive.sh"] = { "verible", "bin", "verible-transform-interactive.sh" },
                    ["verible-verilog-diff"] = { "verible", "bin", "verible-verilog-ls" },
                    ["verible-verilog-format"] = { "verible", "bin", "verible-verilog-format" },
                    ["verible-verilog-kythe-extractor"] = { "verible", "bin", "verible-verilog-kythe-extractor" },
                    ["verible-verilog-lint"] = { "verible", "bin", "verible-verilog-lint" },
                    ["verible-verilog-ls"] = { "verible", "bin", "verible-verilog-ls" },
                    ["verible-verilog-obfuscate"] = { "verible", "bin", "verible-verilog-obfuscate" },
                    ["verible-verilog-preprocessor"] = { "verible", "bin", "verible-verilog-preprocessor" },
                    ["verible-verilog-project"] = { "verible", "bin", "verible-verilog-project" },
                    ["verible-verilog-syntax"] = { "verible", "bin", "verible-verilog-syntax" },
                } do
                    ctx:link_bin(executable, path.concat(rel_path))
                end
            end,
            win = function()
                local source = github.unzip_release_file {
                    repo = repo,
                    asset_file = coalesce(when(platform.is.win_x64, _.format "verible-%s-win64.zip")),
                }
                source.with_receipt()
                ctx.fs:rename(("verible-%s-win64"):format(source.release), "verible")
                for executable, rel_path in pairs {
                    ["verible-patch-tool"] = { "verible", "verible-patch-tool.exe" },
                    ["verible-verilog-diff"] = { "verible", "verible-verilog-ls.exe" },
                    ["verible-verilog-format"] = { "verible", "verible-verilog-format.exe" },
                    ["verible-verilog-kythe-extractor"] = { "verible", "verible-verilog-kythe-extractor.exe" },
                    ["verible-verilog-lint"] = { "verible", "verible-verilog-lint.exe" },
                    ["verible-verilog-ls"] = { "verible", "verible-verilog-ls.exe" },
                    ["verible-verilog-obfuscate"] = { "verible", "verible-verilog-obfuscate.exe" },
                    ["verible-verilog-preprocessor"] = { "verible", "verible-verilog-preprocessor.exe" },
                    ["verible-verilog-project"] = { "verible", "verible-verilog-project.exe" },
                    ["verible-verilog-syntax"] = { "verible", "verible-verilog-syntax.exe" },
                } do
                    ctx:link_bin(executable, path.concat(rel_path))
                end
            end,
        }
    end,
}
