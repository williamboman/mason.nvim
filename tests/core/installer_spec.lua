local spy = require "luassert.spy"
local match = require "luassert.match"
local fs = require "nvim-lsp-installer.core.fs"
local a = require "nvim-lsp-installer.core.async"
local installer = require "nvim-lsp-installer.core.installer"
local InstallContext = require "nvim-lsp-installer.core.installer.context"
local process = require "nvim-lsp-installer.core.process"
local Optional = require "nvim-lsp-installer.core.optional"

local function timestamp()
    local seconds, microseconds = vim.loop.gettimeofday()
    return (seconds * 1000) + math.floor(microseconds / 1000)
end

describe("installer", function()
    it(
        "should call installer",
        async_test(function()
            spy.on(fs.async, "mkdirp")
            spy.on(fs.async, "rename")
            local installer_fn = spy.new(
                ---@param c InstallContext
                function(c)
                    c.receipt:with_primary_source(c.receipt.npm "the-pkg")
                end
            )
            local destination_dir = ("%s/installer_spec"):format(os.getenv "INSTALL_ROOT_DIR")
            local ctx = InstallContext.new {
                name = "installer_spec_success",
                destination_dir = destination_dir,
                boundary_path = os.getenv "INSTALL_ROOT_DIR",
                stdio_sink = process.empty_sink(),
                requested_version = Optional.empty(),
            }
            local result = installer.execute(ctx, function(...)
                installer_fn(...)
            end)
            assert.is_nil(result:err_or_nil())
            assert.spy(installer_fn).was_called(1)
            assert.spy(installer_fn).was_called_with(match.ref(ctx))
            assert.spy(fs.async.mkdirp).was_called(1)
            assert.spy(fs.async.mkdirp).was_called_with(destination_dir .. ".tmp")
            assert.spy(fs.async.rename).was_called(1)
            assert.spy(fs.async.rename).was_called_with(destination_dir .. ".tmp", destination_dir)
        end)
    )

    it(
        "should return failure if installer errors",
        async_test(function()
            spy.on(fs.async, "rmrf")
            local installer_fn = spy.new(function()
                error("something went wrong. don't try again.", 4) -- 4 because spy.new callstack
            end)
            local destination_dir = ("%s/installer_spec_failure"):format(os.getenv "INSTALL_ROOT_DIR")
            local ctx = InstallContext.new {
                name = "installer_spec_failure",
                destination_dir = destination_dir,
                boundary_path = os.getenv "INSTALL_ROOT_DIR",
                stdio_sink = process.empty_sink(),
                requested_version = Optional.empty(),
            }
            local result = installer.execute(ctx, function(...)
                installer_fn(...)
            end)
            assert.spy(installer_fn).was_called(1)
            assert.spy(installer_fn).was_called_with(match.ref(ctx))
            assert.is_true(result:is_failure())
            assert.equals("something went wrong. don't try again.", result:err_or_nil())
            assert.spy(fs.async.rmrf).was_called(2)
            assert.spy(fs.async.rmrf).was_called_with(destination_dir .. ".tmp")
            assert.spy(fs.async.rmrf).was_not_called_with(destination_dir)
        end)
    )

    it(
        "should write receipt",
        async_test(function()
            spy.on(fs.async, "write_file")
            local destination_dir = ("%s/installer_spec_receipt"):format(os.getenv "INSTALL_ROOT_DIR")
            local ctx = InstallContext.new {
                name = "installer_spec_receipt",
                destination_dir = destination_dir,
                boundary_path = os.getenv "INSTALL_ROOT_DIR",
                stdio_sink = process.empty_sink(),
                requested_version = Optional.empty(),
            }
            installer.execute(ctx, function(c)
                c.receipt:with_primary_source(c.receipt.npm "my-pkg")
            end)
            assert.spy(fs.async.write_file).was_called(1)
            assert.spy(fs.async.write_file).was_called_with(
                ("%s.tmp/nvim-lsp-installer-receipt.json"):format(destination_dir),
                match.is_string()
            )
        end)
    )

    it(
        "should run async functions concurrently",
        async_test(function()
            spy.on(fs.async, "write_file")
            local destination_dir = ("%s/installer_spec_concurrent"):format(os.getenv "INSTALL_ROOT_DIR")
            local ctx = InstallContext.new {
                name = "installer_spec_receipt",
                destination_dir = destination_dir,
                boundary_path = os.getenv "INSTALL_ROOT_DIR",
                stdio_sink = process.empty_sink(),
                requested_version = Optional.empty(),
            }
            local capture = spy.new()
            local start = timestamp()
            installer.run_installer(ctx, function(c)
                capture(c:run_concurrently {
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
                c.receipt:with_primary_source(c.receipt.npm "my-pkg")
            end)
            local stop = timestamp()
            local grace_ms = 25
            assert.is_true((stop - start) >= (100 - grace_ms))
            assert.spy(capture).was_called_with(match.is_ref(ctx), "two", "three")
        end)
    )
end)
