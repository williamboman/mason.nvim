local cargo_check = require "nvim-lsp-installer.jobs.outdated-servers.cargo"

describe("cargo outdated package checker", function()
    it("parses cargo installed packages output", function()
        assert.equal(
            vim.inspect {
                ["bat"] = "0.18.3",
                ["exa"] = "0.10.1",
                ["git-select-branch"] = "0.1.1",
                ["hello_world"] = "0.0.1",
                ["rust-analyzer"] = "0.0.0",
                ["stylua"] = "0.11.2",
                ["zoxide"] = "0.5.0",
            },
            vim.inspect(cargo_check.parse_installed_crates [[bat v0.18.3:
    bat
exa v0.10.1:
    exa
git-select-branch v0.1.1:
    git-select-branch
hello_world v0.0.1 (/private/var/folders/ky/s6yyhm_d24d0jsrql4t8k4p40000gn/T/tmp.LGbguATJHj):
    hello_world
rust-analyzer v0.0.0 (/private/var/folders/ky/s6yyhm_d24d0jsrql4t8k4p40000gn/T/tmp.YlsHeA9JVL/crates/rust-analyzer):
    rust-analyzer
stylua v0.11.2:
    stylua
zoxide v0.5.0:
    zoxide
]])
        )
    end)
end)
