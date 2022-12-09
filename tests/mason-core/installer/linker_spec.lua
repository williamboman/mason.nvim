local stub = require "luassert.stub"
local fs = require "mason-core.fs"
local path = require "mason-core.path"
local registry = require "mason-registry"

local WIN_CMD_SCRIPT = [[@ECHO off
GOTO start
:find_dp0
SET dp0=%%~dp0
EXIT /b
:start
SETLOCAL
CALL :find_dp0

endLocal & goto #_undefined_# 2>NUL || title %%COMSPEC%% & "%%dp0%%\%s" %%*]]

describe("installer", function()
    ---@module "mason-core.installer.linker"
    local linker
    ---@module "mason-core.platform"
    local platform

    before_each(function()
        package.loaded["mason-core.installer.platform"] = nil
        package.loaded["mason-core.installer.linker"] = nil
        platform = require "mason-core.platform"
        linker = require "mason-core.installer.linker"
    end)

    it(
        "should symlink executable on Unix",
        async_test(function()
            local dummy = registry.get_package "dummy"
            stub(fs.async, "file_exists")
            stub(fs.async, "symlink")
            stub(fs.async, "write_file")

            fs.async.file_exists.on_call_with(path.bin_prefix "my-executable").returns(false)
            fs.async.file_exists.on_call_with(path.bin_prefix "another-executable").returns(false)
            fs.async.file_exists
                .on_call_with(path.concat { dummy:get_install_path(), "nested", "path", "my-executable" })
                .returns(true)
            fs.async.file_exists
                .on_call_with(path.concat { dummy:get_install_path(), "another-executable" })
                .returns(true)

            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            ctx:link_bin("my-executable", path.concat { "nested", "path", "my-executable" })
            ctx:link_bin("another-executable", "another-executable")
            linker.link(ctx)

            assert.spy(fs.async.write_file).was_called(0)
            assert.spy(fs.async.symlink).was_called(2)
            assert
                .spy(fs.async.symlink)
                .was_called_with("../packages/dummy/another-executable", path.bin_prefix "another-executable")
            assert
                .spy(fs.async.symlink)
                .was_called_with("../packages/dummy/nested/path/my-executable", path.bin_prefix "my-executable")
        end)
    )

    it(
        "should write executable wrapper on Windows",
        async_test(function()
            platform.is.darwin = false
            platform.is.mac = false
            platform.is.linux = false
            platform.is.unix = false
            platform.is.win = true

            local dummy = registry.get_package "dummy"
            stub(fs.async, "file_exists")
            stub(fs.async, "symlink")
            stub(fs.async, "write_file")

            fs.async.file_exists.on_call_with(path.bin_prefix "my-executable").returns(false)
            fs.async.file_exists.on_call_with(path.bin_prefix "another-executable").returns(false)
            fs.async.file_exists
                .on_call_with(path.concat { dummy:get_install_path(), "nested", "path", "my-executable" })
                .returns(true)
            fs.async.file_exists
                .on_call_with(path.concat { dummy:get_install_path(), "another-executable" })
                .returns(true)

            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            ctx:link_bin("my-executable", path.concat { "nested", "path", "my-executable" })
            ctx:link_bin("another-executable", "another-executable")
            linker.link(ctx)

            assert.spy(fs.async.symlink).was_called(0)
            assert.spy(fs.async.write_file).was_called(2)
            assert
                .spy(fs.async.write_file)
                .was_called_with(path.bin_prefix "another-executable.cmd", WIN_CMD_SCRIPT:format "../packages/dummy/another-executable")
            assert
                .spy(fs.async.write_file)
                .was_called_with(
                    path.bin_prefix "my-executable.cmd",
                    WIN_CMD_SCRIPT:format "../packages/dummy/nested/path/my-executable"
                )
        end)
    )
end)
