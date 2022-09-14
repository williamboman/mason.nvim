local spy = require "luassert.spy"
local match = require "luassert.match"
local fs = require "mason-core.fs"
local a = require "mason-core.async"
local path = require "mason-core.path"
local installer = require "mason-core.installer"
local InstallContext = require "mason-core.installer.context"

local function timestamp()
    local seconds, microseconds = vim.loop.gettimeofday()
    return (seconds * 1000) + math.floor(microseconds / 1000)
end

describe("installer", function()
    before_each(function()
        package.loaded["dummy_package"] = nil
    end)

    it(
        "should call installer",
        async_test(function()
            spy.on(fs.async, "mkdirp")
            spy.on(fs.async, "rename")

            local handle = InstallHandleGenerator "dummy"
            spy.on(handle.package.spec, "install")
            local result = installer.execute(handle, {})

            assert.is_nil(result:err_or_nil())
            assert.spy(handle.package.spec.install).was_called(1)
            assert.spy(handle.package.spec.install).was_called_with(match.instanceof(InstallContext))
            assert.spy(fs.async.mkdirp).was_called_with(path.package_build_prefix "dummy")
            assert.spy(fs.async.rename).was_called_with(path.package_build_prefix "dummy", path.package_prefix "dummy")
        end)
    )

    it(
        "should return failure if installer errors",
        async_test(function()
            spy.on(fs.async, "rmrf")
            spy.on(fs.async, "rename")
            local installer_fn = spy.new(function()
                error("something went wrong. don't try again.", 0)
            end)
            local handler = InstallHandleGenerator "dummy"
            handler.package.spec.install = installer_fn
            local result = installer.execute(handler, {})
            assert.spy(installer_fn).was_called(1)
            assert.is_true(result:is_failure())
            assert.is_true(match.has_match "^.*: something went wrong. don't try again.$"(result:err_or_nil()))
            assert.spy(fs.async.rmrf).was_called_with(path.package_build_prefix "dummy")
            assert.spy(fs.async.rename).was_not_called()
        end)
    )

    it(
        "should write receipt",
        async_test(function()
            spy.on(fs.async, "write_file")
            local handler = InstallHandleGenerator "dummy"
            ---@param ctx InstallContext
            handler.package.spec.install = function(ctx)
                ctx.receipt:with_primary_source { type = "source", metadata = {} }
                ctx.fs:write_file("target", "script-contents")
                ctx:link_bin("executable", "target")
            end
            installer.execute(handler, {})
            assert.spy(fs.async.write_file).was_called_with(
                ("%s/mason-receipt.json"):format(handler.package:get_install_path()),
                match.capture(function(arg)
                    ---@type InstallReceipt
                    local receipt = vim.json.decode(arg)
                    assert.equals("dummy", receipt.name)
                    assert.same({ type = "source", metadata = {} }, receipt.primary_source)
                    assert.same({}, receipt.secondary_sources)
                    assert.same("1.0", receipt.schema_version)
                    assert.same({ bin = { executable = "target" } }, receipt.links)
                end)
            )
        end)
    )

    it(
        "should run async functions concurrently",
        async_test(function()
            spy.on(fs.async, "write_file")
            local capture = spy.new()
            local start = timestamp()
            local handle = InstallHandleGenerator "dummy"
            handle.package.spec.install = function(ctx)
                capture(installer.run_concurrently {
                    function()
                        a.sleep(100)
                        return installer.context()
                    end,
                    function()
                        a.sleep(100)
                        return "two"
                    end,
                    function()
                        a.sleep(100)
                        return "three"
                    end,
                })
                ctx.receipt:with_primary_source { type = "dummy" }
            end
            installer.execute(handle, {})
            local stop = timestamp()
            local grace_ms = 25
            assert.is_true((stop - start) >= (100 - grace_ms))
            assert.spy(capture).was_called_with(match.instanceof(InstallContext), "two", "three")
        end)
    )
end)
