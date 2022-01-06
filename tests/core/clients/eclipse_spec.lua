local eclipse = require "nvim-lsp-installer.core.clients.eclipse"

describe("eclipse client", function()
    it("parses jdtls version strings", function()
        assert.equal(
            "1.8.0-202112170540",
            eclipse._parse_jdtls_version_string "jdt-language-server-1.8.0-202112170540.tar.gz"
        )
    end)
end)
