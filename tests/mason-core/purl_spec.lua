local Result = require "mason-core.result"
local purl = require "mason-core.purl"

describe("purl", function()
    it("should parse well-formed PURLs", function()
        assert.same(
            Result.success {
                name = "rust-analyzer",
                namespace = "rust-lang",
                qualifiers = {
                    target = "linux_x64_gnu",
                    download_url = "https://github.com/rust-lang/rust-analyzer/releases/download/2022-11-28/rust-analyzer-x86_64-unknown-linux-gnu.gz",
                },
                scheme = "pkg",
                type = "github",
                version = "2022-11-28",
                subpath = "bin/rust-analyzer",
            },
            purl.parse "pkg:github/rust-lang/rust-analyzer@2022-11-28?target=linux_x64_gnu&download_url=https://github.com/rust-lang/rust-analyzer/releases/download/2022-11-28/rust-analyzer-x86_64-unknown-linux-gnu.gz#bin/rust-analyzer"
        )

        assert.same(
            Result.success {
                scheme = "pkg",
                type = "github",
                namespace = "rust-lang",
                name = "rust-analyzer",
                version = "2025-04-20",
                qualifiers = nil,
                subpath = nil,
            },
            purl.parse "pkg:github/rust-lang/rust-analyzer@2025-04-20"
        )

        assert.same(
            Result.success {
                scheme = "pkg",
                type = "npm",
                namespace = nil,
                name = "typescript-language-server",
                version = "10.23.1",
                qualifiers = nil,
                subpath = nil,
            },
            purl.parse "pkg:npm/typescript-language-server@10.23.1"
        )

        assert.same(
            Result.success {
                scheme = "pkg",
                type = "pypi",
                namespace = nil,
                name = "python-language-server",
                version = nil,
                qualifiers = nil,
                subpath = nil,
            },
            purl.parse "pkg:pypi/python-language-server"
        )

        assert.same(
            Result.success {
                name = "cli",
                namespace = "@angular",
                scheme = "pkg",
                type = "npm",
            },
            purl.parse "pkg:npm/%40angular/cli"
        )
    end)

    it("should fail to parse invalid PURLs", function()
        assert.same(Result.failure "Malformed purl (invalid scheme).", purl.parse "scam:github/react@18.0.0")
    end)
end)

describe("purl test suite ::", function()
    local fs = require "mason-core.fs"
    ---@type { description: string, purl: string, type: string?, namespace: string, name: string?, version: string?, is_invalid: boolean, canonical_purl: string }[]
    local test_fixture = vim.json.decode(fs.sync.read_file "./tests/fixtures/purl-test-suite-data.json")

    local function not_vim_nil(val)
        if val == vim.NIL then
            return nil
        else
            return val
        end
    end

    for _, test in ipairs(test_fixture) do
        it(test.description, function()
            local result = purl.parse(test.purl)
            if test.is_invalid then
                assert.is_true(result:is_failure())
            else
                assert.same(
                    Result.success {
                        scheme = "pkg",
                        type = not_vim_nil(test.type),
                        namespace = not_vim_nil(test.namespace),
                        name = not_vim_nil(test.name),
                        version = not_vim_nil(test.version),
                        qualifiers = not_vim_nil(test.qualifiers),
                        subpath = not_vim_nil(test.subpath),
                    },
                    result
                )

                assert.equals(test.canonical_purl, purl.compile(result:get_or_throw()))
            end
        end)
    end
end)
