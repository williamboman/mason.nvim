local _ = require "nvim-lsp-installer.core.functional"

describe("functional: string", function()
    it("matches string patterns", function()
        assert.is_true(_.matches("foo", "foo"))
        assert.is_true(_.matches("bar", "foobarbaz"))
        assert.is_true(_.matches("ba+r", "foobaaaaaaarbaz"))

        assert.is_false(_.matches("ba+r", "foobharbaz"))
        assert.is_false(_.matches("bar", "foobaz"))
    end)

    it("should format strings", function()
        assert.equals("Hello World!", _.format("%s", "Hello World!"))
        assert.equals("special manouvers", _.format("%s manouvers", "special"))
    end)
end)
