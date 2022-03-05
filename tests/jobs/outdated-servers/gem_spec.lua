local gem_check = require "nvim-lsp-installer.jobs.outdated-servers.gem"

describe("gem outdated package checker", function()
    it("parses outdated gem output", function()
        local normalize = gem_check.parse_outdated_gem
        assert.equal(
            vim.inspect {
                name = "solargraph",
                current_version = "0.42.2",
                latest_version = "0.44.2",
            },
            vim.inspect(normalize [[solargraph (0.42.2 < 0.44.2)]])
        )
        assert.equal(
            vim.inspect {
                name = "sorbet-runtime",
                current_version = "0.5.9307",
                latest_version = "0.5.9468",
            },
            vim.inspect(normalize [[sorbet-runtime (0.5.9307 < 0.5.9468)]])
        )
    end)

    it("returns nil when unable to parse outdated gem", function()
        assert.is_nil(gem_check.parse_outdated_gem "a whole bunch of gibberish!")
        assert.is_nil(gem_check.parse_outdated_gem "")
    end)

    it("should parse gem list output", function()
        assert.equals(
            vim.inspect {
                ["solargraph"] = "0.44.3",
                ["unicode-display_width"] = "2.1.0",
            },
            vim.inspect(gem_check.parse_gem_list_output [[

*** LOCAL GEMS ***

nokogiri (1.13.3 arm64-darwin)
solargraph (0.44.3)
unicode-display_width (2.1.0)
]])
        )
    end)
end)
