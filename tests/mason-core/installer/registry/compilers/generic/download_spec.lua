local Purl = require "mason-core.purl"
local Result = require "mason-core.result"
local generic = require "mason-core.installer.compiler.compilers.generic"
local stub = require "luassert.stub"
local test_helpers = require "mason-test.helpers"

---@param overrides Purl
local function purl(overrides)
    local purl = Purl.parse("pkg:generic/namespace/name@v1.2.0"):get_or_throw()
    if not overrides then
        return purl
    end
    return vim.tbl_deep_extend("force", purl, overrides)
end

describe("generic provider :: download :: parsing", function()
    it("should parse single download target", function()
        assert.same(
            Result.success {
                download = {
                    files = {
                        ["name.tar.gz"] = [[https://getpackage.org/downloads/1.2.0/name.tar.gz]],
                    },
                },
            },
            generic.parse({
                download = {
                    files = {
                        ["name.tar.gz"] = [[https://getpackage.org/downloads/{{version | strip_prefix "v"}}/name.tar.gz]],
                    },
                },
            }, purl())
        )
    end)

    it("should coalesce download target", function()
        assert.same(
            Result.success {
                download = {
                    target = "linux_arm64",
                    files = {
                        ["name.tar.gz"] = [[https://getpackage.org/downloads/linux-aarch64/1.2.0/name.tar.gz]],
                    },
                },
            },
            generic.parse({
                download = {
                    {
                        target = "linux_arm64",
                        files = {
                            ["name.tar.gz"] = [[https://getpackage.org/downloads/linux-aarch64/{{version | strip_prefix "v"}}/name.tar.gz]],
                        },
                    },
                    {
                        target = "win_arm64",
                        files = {
                            ["name.tar.gz"] = [[https://getpackage.org/downloads/win-aarch64/{{version | strip_prefix "v"}}/name.tar.gz]],
                        },
                    },
                },
            }, purl(), { target = "linux_arm64" })
        )
    end)

    it("should check supported platforms", function()
        assert.same(
            Result.failure "PLATFORM_UNSUPPORTED",
            generic.parse(
                {
                    download = {
                        {
                            target = "win_arm64",
                            files = {
                                ["name.tar.gz"] = [[https://getpackage.org/downloads/win-aarch64/{{version | strip_prefix "v"}}/name.tar.gz]],
                            },
                        },
                    },
                },
                purl(),
                {
                    target = "linux_arm64",
                }
            )
        )
    end)
end)

describe("generic provider :: download :: installing", function()
    local snapshot

    before_each(function()
        snapshot = assert.snapshot()
    end)

    after_each(function()
        snapshot:revert()
    end)

    it("should install generic packages", function()
        local ctx = test_helpers.create_context()
        local std = require "mason-core.installer.managers.std"
        stub(std, "download_file", mockx.returns(Result.success()))
        stub(std, "unpack", mockx.returns(Result.success()))

        local result = ctx:execute(function()
            return generic.install(ctx, {
                download = {
                    files = {
                        ["name.tar.gz"] = [[https://getpackage.org/downloads/linux-aarch64/1.2.0/name.tar.gz]],
                        ["archive.tar.gz"] = [[https://getpackage.org/downloads/linux-aarch64/1.2.0/archive.tar.gz]],
                    },
                },
            })
        end)

        assert.is_true(result:is_success())
        assert.spy(std.download_file).was_called(2)
        assert
            .spy(std.download_file)
            .was_called_with("https://getpackage.org/downloads/linux-aarch64/1.2.0/name.tar.gz", "name.tar.gz")
        assert
            .spy(std.download_file)
            .was_called_with("https://getpackage.org/downloads/linux-aarch64/1.2.0/archive.tar.gz", "archive.tar.gz")
        assert.spy(std.unpack).was_called(2)
        assert.spy(std.unpack).was_called_with "name.tar.gz"
        assert.spy(std.unpack).was_called_with "archive.tar.gz"
    end)
end)
