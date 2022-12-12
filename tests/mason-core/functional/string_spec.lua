local _ = require "mason-core.functional"

describe("functional: string", function()
    it("matches string patterns", function()
        assert.is_true(_.matches("foo", "foo"))
        assert.is_true(_.matches("bar", "foobarbaz"))
        assert.is_true(_.matches("ba+r", "foobaaaaaaarbaz"))

        assert.is_false(_.matches("ba+r", "foobharbaz"))
        assert.is_false(_.matches("bar", "foobaz"))
    end)

    it("returns string pattern matches", function()
        assert.same({ "foo" }, _.match("foo", "foo"))
        assert.same({ "foo", "bar", "baz" }, _.match("(foo) (bar) (baz)", "foo bar baz"))
    end)

    it("should format strings", function()
        assert.equals("Hello World!", _.format("%s", "Hello World!"))
        assert.equals("special manouvers", _.format("%s manouvers", "special"))
    end)

    it("should split strings", function()
        assert.same({ "This", "is", "a", "sentence" }, _.split("%s", "This is a sentence"))
        assert.same({ "This", "is", "a", "sentence" }, _.split("|", "This|is|a|sentence"))
    end)

    it("should gsub strings", function()
        assert.same("predator", _.gsub("^apex%s*", "", "apex predator"))
    end)

    it("should dedent strings", function()
        assert.equals(
            [[Lorem
Ipsum
    Dolor
  Sit
 Amet]],
            _.dedent [[
    Lorem
    Ipsum
        Dolor
      Sit
     Amet
]]
        )
    end)

    it("should transform casing", function()
        assert.equals("HELLO!", _.to_upper "Hello!")
        assert.equals("hello!", _.to_lower "Hello!")
    end)
end)
