local Result = require "mason-core.result"
local go = require "mason-core.managers.go"
local installer = require "mason-core.installer"
local mock = require "luassert.mock"
local path = require "mason-core.path"
local spawn = require "mason-core.spawn"
local spy = require "luassert.spy"
local stub = require "luassert.stub"

describe("go manager", function()
    it(
        "should call go install",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "42.13.37" })
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, go.packages { "main-package", "supporting-package", "supporting-package2" })
            assert.spy(ctx.spawn.go).was_called(3)
            assert.spy(ctx.spawn.go).was_called_with {
                "install",
                "-v",
                "main-package@42.13.37",
                env = { GOBIN = path.package_build_prefix "dummy" },
            }
            assert.spy(ctx.spawn.go).was_called_with {
                "install",
                "-v",
                "supporting-package@latest",
                env = { GOBIN = path.package_build_prefix "dummy" },
            }
            assert.spy(ctx.spawn.go).was_called_with {
                "install",
                "-v",
                "supporting-package2@latest",
                env = { GOBIN = path.package_build_prefix "dummy" },
            }
        end)
    )

    it(
        "should provide receipt information",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "42.13.37" })
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, go.packages { "main-package", "supporting-package", "supporting-package2" })
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
        path    golang.org/x/tools/cmd
        mod     golang.org/x/tools/cmd        v0.8.1  h1:q5nDpRopYrnF4DN/1o8ZQ7Oar4Yd4I5OtGMx5RyV2/8=
        dep     github.com/google/go-cmp        v0.5.7  h1:81/ik6ipDQS2aGcBfIN5dHDB36BwrStyeAQquSYCV4o=
        dep     mvdan.cc/xurls/v2       v2.4.0  h1:tzxjVAj+wSBmDcF6zBB7/myTy3gX9xvi8Tyr28AuQgc=
        build   -compiler=gc
        build   GOOS=darwin
]]

    it("should parse go version output", function()
        local parsed = go.parse_mod_version_output(go_version_output)
        assert.same({
            path = { ["golang.org/x/tools/cmd"] = "" },
            mod = { ["golang.org/x/tools/cmd"] = "v0.8.1" },
            dep = { ["github.com/google/go-cmp"] = "v0.5.7", ["mvdan.cc/xurls/v2"] = "v2.4.0" },
            build = { ["-compiler=gc"] = "", ["GOOS=darwin"] = "" },
        }, parsed)
    end)

    it(
        "should return current version",
        async_test(function()
            stub(spawn, "go")
            spawn.go.returns(Result.success { stdout = go_version_output })

            local result = go.get_installed_primary_package_version(
                mock.new {
                    primary_source = mock.new {
                        type = "go",
                        package = "golang.org/x/tools/cmd/gopls/...",
                    },
                },
                path.package_prefix "dummy"
            )

            assert.spy(spawn.go).was_called(1)
            assert.spy(spawn.go).was_called_with {
                "version",
                "-m",
                "gopls",
                cwd = path.package_prefix "dummy",
            }
            assert.is_true(result:is_success())
            assert.equals("v0.8.1", result:get_or_nil())
        end)
    )

    it(
        "should return outdated primary package",
        async_test(function()
            stub(spawn, "go")
            spawn.go
                .on_call_with({
                    "list",
                    "-json",
                    "-m",
                    "golang.org/x/tools/cmd@latest",
                    cwd = path.package_prefix "dummy",
                })
                .returns(Result.success {
                    stdout = ([[
            {
                "Path": %q,
                "Version": "v2.0.0"
            }
            ]]):format(path.package_prefix "dummy"),
                })
            spawn.go
                .on_call_with({
                    "version",
                    "-m",
                    "gopls",
                    cwd = path.package_prefix "dummy",
                })
                .returns(Result.success {
                    stdout = go_version_output,
                })

            local result = go.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "go",
                        package = "golang.org/x/tools/cmd/gopls/...",
                    },
                },
                path.package_prefix "dummy"
            )

            assert.is_true(result:is_success())
            assert.same({
                name = "golang.org/x/tools/cmd",
                current_version = "v0.8.1",
                latest_version = "v2.0.0",
            }, result:get_or_nil())
        end)
    )

    it("should parse package mod names", function()
        assert.equals("github.com/cweill/gotests", go.parse_package_mod "github.com/cweill/gotests/...")
        assert.equals("golang.org/x/tools/gopls", go.parse_package_mod "golang.org/x/tools/gopls/...")
        assert.equals("golang.org/x/crypto", go.parse_package_mod "golang.org/x/crypto/...")
        assert.equals("github.com/go-delve/delve", go.parse_package_mod "github.com/go-delve/delve/cmd/dlv")
        assert.equals("mvdan.cc/sh/v3", go.parse_package_mod "mvdan.cc/sh/v3/cmd/shfmt")
    end)
end)
