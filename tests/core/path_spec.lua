local path = require "nvim-lsp-installer.core.path"

describe("path", function()
    it("concatenates paths", function()
        assert.equal("foo/bar/baz/~", path.concat { "foo", "bar", "baz", "~" })
    end)

    it("concatenates paths on Windows", function()
        local old_os = jit.os
        jit.os = "windows"
        package.loaded["nvim-lsp-installer.core.path"] = nil
        local path = require "nvim-lsp-installer.core.path"
        assert.equal([[foo\bar\baz\~]], path.concat { "foo", "bar", "baz", "~" })
        jit.os = old_os
    end)

    it("identifies subdirectories", function()
        assert.is_true(path.is_subdirectory("/foo/bar", "/foo/bar/baz"))
        assert.is_true(path.is_subdirectory("/foo/bar", "/foo/bar"))
        assert.is_false(path.is_subdirectory("/foo/bar", "/foo/bas/baz"))
        assert.is_false(path.is_subdirectory("/foo/bar", "/foo/bars/baz"))
    end)
end)
