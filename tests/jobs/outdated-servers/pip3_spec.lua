local pip3_check = require "nvim-lsp-installer.jobs.outdated-servers.pip3"

describe("pip3 outdated package checker", function()
    it("normalizes pip3 packages", function()
        local normalize = pip3_check.normalize_package
        assert.equal("python-lsp-server", normalize "python-lsp-server[all]")
        assert.equal("python-lsp-server", normalize "python-lsp-server[]")
        assert.equal("python-lsp-server", normalize "python-lsp-server[[]]")
    end)
end)
