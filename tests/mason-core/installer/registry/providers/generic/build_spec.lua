local Purl = require "mason-core.purl"
local Result = require "mason-core.result"
local generic = require "mason-core.installer.registry.providers.generic"
local installer = require "mason-core.installer"
local stub = require "luassert.stub"

---@param overrides Purl
local function purl(overrides)
    local purl = Purl.parse("pkg:generic/namespace/name@v1.2.0"):get_or_throw()
    if not overrides then
        return purl
    end
    return vim.tbl_deep_extend("force", purl, overrides)
end

describe("generic provider :: build :: parsing", function()
    it("should parse single build target", function()
        assert.same(
            Result.success {
                build = {
                    run = "make build",
                    env = {
                        SOME_VALUE = "here",
                    },
                },
            },
            generic.parse({
                build = {
                    run = "make build",
                    env = {
                        SOME_VALUE = "here",
                    },
                },
            }, purl())
        )
    end)

    it("should coalesce build target", function()
        assert.same(
            Result.success {
                build = {
                    target = "linux_arm64",
                    run = "make build",
                    env = {
                        LINUX = "yes",
                    },
                },
            },
            generic.parse({
                build = {
                    {
                        target = "linux_arm64",
                        run = "make build",
                        env = {
                            LINUX = "yes",
                        },
                    },
                    {
                        target = "win_arm64",
                        run = "make build",
                        env = {
                            WINDOWS = "yes",
                        },
                    },
                },
            }, purl(), { target = "linux_arm64" })
        )
    end)

    it("should interpolate environment", function()
        assert.same(
            Result.success {
                build = {
                    run = "make build",
                    env = {
                        LINUX = "2023-04-18",
                    },
                },
            },
            generic.parse(
                {
                    build = {
                        run = "make build",
                        env = {
                            LINUX = "{{version}}",
                        },
                    },
                },
                purl { version = "2023-04-18" },
                {
                    target = "linux_arm64",
                }
            )
        )
    end)

    it("should check supported platforms", function()
        assert.same(
            Result.failure "PLATFORM_UNSUPPORTED",
            generic.parse(
                {
                    build = {
                        {
                            target = "win_arm64",
                            run = "make build",
                            env = {
                                WINDOWS = "yes",
                            },
                        },
                    },
                },
                purl(),
                {
                    target = "linux_x64",
                }
            )
        )
    end)
end)

describe("generic provider :: build :: installing", function()
    it("should install", function()
        local ctx = create_dummy_context()
        local build = require "mason-core.installer.managers.build"
        stub(build, "run", mockx.returns(Result.success()))

        local result = installer.exec_in_context(ctx, function()
            return generic.install(ctx, {
                build = {
                    run = "make",
                    env = { VALUE = "here" },
                },
            })
        end)

        assert.is_true(result:is_success())
        assert.spy(build.run).was_called(1)
        assert.spy(build.run).was_called_with {
            run = "make",
            env = { VALUE = "here" },
        }
    end)
end)
