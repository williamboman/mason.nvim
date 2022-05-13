local client = require "nvim-lsp-installer.core.managers.github.client"

describe("github client", function()
    ---@type GitHubRelease
    local release = {
        tag_name = "v0.1.0",
        prerelease = false,
        draft = false,
        assets = {},
    }

    local function stub_release(mock)
        return setmetatable(mock, { __index = release })
    end

    it("should identify stable prerelease", function()
        local predicate = client.release_predicate {
            include_prerelease = false,
        }

        assert.is_false(predicate(stub_release { prerelease = true }))
        assert.is_true(predicate(stub_release { prerelease = false }))
    end)

    it("should identify stable release with tag name pattern", function()
        local predicate = client.release_predicate {
            tag_name_pattern = "^lsp%-server.*$",
        }

        assert.is_false(predicate(stub_release { tag_name = "v0.1.0" }))
        assert.is_true(predicate(stub_release { tag_name = "lsp-server-v0.1.0" }))
    end)

    it("should identify stable release", function()
        local predicate = client.release_predicate {}

        assert.is_true(predicate(stub_release { tag_name = "v0.1.0" }))
        assert.is_false(predicate(stub_release { prerelease = true }))
        assert.is_false(predicate(stub_release { draft = true }))
    end)
end)
