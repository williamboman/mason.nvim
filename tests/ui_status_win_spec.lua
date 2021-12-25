local ServerHints = require "nvim-lsp-installer.ui.status-win.server_hints"

describe("status win server hints", function()
    it("should produce valid server hints", function()
        local srv = ServerGenerator {
            name = "rust_analyzer",
            languages = { "rust", "analyz", "totallynotjavascript" },
        }
        local hints = ServerHints.new(srv)
        assert.equal(vim.inspect { "analyz", "totallynotjavascript" }, vim.inspect(hints:get_hints()))
        assert.equal("(analyz, totallynotjavascript)", tostring(hints))
    end)

    it("should not produce server hints", function()
        local srv = ServerGenerator {
            name = "rust_analyzer",
            languages = { "rust" },
        }
        local srv2 = ServerGenerator {
            name = "cssmodules_ls",
            languages = { "css" },
        }
        local hints = ServerHints.new(srv)
        assert.equal(vim.inspect {}, vim.inspect(hints:get_hints()))
        assert.equal("", tostring(hints))

        local hints2 = ServerHints.new(srv2)
        assert.equal(vim.inspect {}, vim.inspect(hints2:get_hints()))
        assert.equal("", tostring(hints2))
    end)

    it("should produce server hints even when there's a match if language is short or long", function()
        local srv = ServerGenerator {
            name = "clangd",
            languages = { "c", "c++" },
        }
        local srv2 = ServerGenerator {
            name = "this_is_a_very_cool_rust_server",
            languages = { "rust" },
        }
        local hints = ServerHints.new(srv)
        assert.equal(vim.inspect { "c", "c++" }, vim.inspect(hints:get_hints()))
        assert.equal("(c, c++)", tostring(hints))

        local hints2 = ServerHints.new(srv2)
        assert.equal(vim.inspect { "rust" }, vim.inspect(hints2:get_hints()))
        assert.equal("(rust)", tostring(hints2))
    end)
end)
