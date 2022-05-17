local _ = require "nvim-lsp-installer.core.functional"

describe("functional: table", function()
    it("retrieves property of table", function()
        assert.equals("hello", _.prop("a", { a = "hello" }))
    end)
end)
