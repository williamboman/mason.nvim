local path = require "mason-core.path"

describe("path", function()
    it("concatenates paths", function()
        assert.equals("foo/bar/baz/~", path.concat { "foo", "bar", "baz", "~" })
    end)

    it("concatenates paths on Windows", function()
        local old_os = jit.os
        -- selene: allow(incorrect_standard_library_use)
        jit.os = "windows"
        package.loaded["mason-core.path"] = nil
        local path = require "mason-core.path"
        assert.equals([[foo\bar\baz\~]], path.concat { "foo", "bar", "baz", "~" })
        -- selene: allow(incorrect_standard_library_use)
        jit.os = old_os
    end)

    it("identifies subdirectories", function()
        assert.is_true(path.is_subdirectory("/foo/bar", "/foo/bar/baz"))
        assert.is_true(path.is_subdirectory("/foo/bar", "/foo/bar"))
        assert.is_false(path.is_subdirectory("/foo/bar", "/foo/bas/baz"))
        assert.is_false(path.is_subdirectory("/foo/bar", "/foo/bars/baz"))
    end)
end)
