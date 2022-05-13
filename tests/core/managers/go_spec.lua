local mock = require "luassert.mock"
local stub = require "luassert.stub"
local spy = require "luassert.spy"
local Optional = require "nvim-lsp-installer.core.optional"
local Result = require "nvim-lsp-installer.core.result"
local go = require "nvim-lsp-installer.core.managers.go"
local spawn = require "nvim-lsp-installer.core.spawn"
local installer = require "nvim-lsp-installer.core.installer"

describe("go manager", function()
    ---@type InstallContext
    local ctx
    before_each(function()
        ctx = InstallContextGenerator {
            spawn = mock.new {
                go = mockx.returns {},
            },
        }
    end)

    it(
        "should call go install",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            installer.run_installer(ctx, go.packages { "main-package", "supporting-package", "supporting-package2" })
            assert.spy(ctx.spawn.go).was_called(3)
            assert.spy(ctx.spawn.go).was_called_with {
                "install",
                "-v",
                "main-package@42.13.37",
                env = { GOBIN = "/tmp/install-dir" },
            }
            assert.spy(ctx.spawn.go).was_called_with {
                "install",
                "-v",
                "supporting-package@latest",
                env = { GOBIN = "/tmp/install-dir" },
            }
            assert.spy(ctx.spawn.go).was_called_with {
                "install",
                "-v",
                "supporting-package2@latest",
                env = { GOBIN = "/tmp/install-dir" },
            }
        end)
    )

    it(
        "should provide receipt information",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            installer.run_installer(ctx, go.packages { "main-package", "supporting-package", "supporting-package2" })
            assert.same({
                type = "go",
                package = "main-package",
            }, ctx.receipt.primary_source)
            assert.same({
                {
                    type = "go",
                    package = "supporting-package",
                },
                {
                    type = "go",
                    package = "supporting-package2",
                },
            }, ctx.receipt.secondary_sources)
        end)
    )
end)

describe("go version check", function()
    local go_version_output = [[
gopls: go1.18
        path    golang.org/x/tools/gopls
        mod     golang.org/x/tools/gopls        v0.8.1  h1:q5nDpRopYrnF4DN/1o8ZQ7Oar4Yd4I5OtGMx5RyV2/8=
        dep     github.com/google/go-cmp        v0.5.7  h1:81/ik6ipDQS2aGcBfIN5dHDB36BwrStyeAQquSYCV4o=
        dep     mvdan.cc/xurls/v2       v2.4.0  h1:tzxjVAj+wSBmDcF6zBB7/myTy3gX9xvi8Tyr28AuQgc=
        build   -compiler=gc
        build   GOOS=darwin
]]

    it("should parse go version output", function()
        local parsed = go.parse_mod_version_output(go_version_output)
        assert.same({
            path = { ["golang.org/x/tools/gopls"] = "" },
            mod = { ["golang.org/x/tools/gopls"] = "v0.8.1" },
            dep = { ["github.com/google/go-cmp"] = "v0.5.7", ["mvdan.cc/xurls/v2"] = "v2.4.0" },
            build = { ["-compiler=gc"] = "", ["GOOS=darwin"] = "" },
        }, parsed)
    end)

    it(
        "should return current version",
        async_test(function()
            spawn.go = spy.new(function()
                return Result.success { stdout = go_version_output }
            end)

            local result = go.get_installed_primary_package_version(
                mock.new {
                    primary_source = mock.new {
                        type = "go",
                        package = "golang.org/x/tools/gopls",
                    },
                },
                "/tmp/install/dir"
            )

            assert.spy(spawn.go).was_called(1)
            assert.spy(spawn.go).was_called_with {
                "version",
                "-m",
                "gopls",
                cwd = "/tmp/install/dir",
            }
            assert.is_true(result:is_success())
            assert.equals("v0.8.1", result:get_or_nil())

            spawn.go = nil
        end)
    )

    it(
        "should return outdated primary package",
        async_test(function()
            stub(spawn, "go")
            spawn.go.on_call_with({
                "list",
                "-json",
                "-m",
                "golang.org/x/tools/gopls@latest",
                cwd = "/tmp/install/dir",
            }).returns(Result.success {
                stdout = [[
            {
                "Path": "/tmp/install/dir",
                "Version": "v2.0.0"
            }
            ]],
            })
            spawn.go.on_call_with({
                "version",
                "-m",
                "gopls",
                cwd = "/tmp/install/dir",
            }).returns(Result.success {
                stdout = go_version_output,
            })

            local result = go.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "go",
                        package = "golang.org/x/tools/gopls",
                    },
                },
                "/tmp/install/dir"
            )

            assert.is_true(result:is_success())
            assert.same({
                name = "golang.org/x/tools/gopls",
                current_version = "v0.8.1",
                latest_version = "v2.0.0",
            }, result:get_or_nil())

            spawn.go = nil
        end)
    )
end)
