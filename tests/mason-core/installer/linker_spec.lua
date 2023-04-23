local fs = require "mason-core.fs"
local path = require "mason-core.path"
local registry = require "mason-registry"
local stub = require "luassert.stub"

local WIN_CMD_SCRIPT = [[@ECHO off
GOTO start
:find_dp0
SET dp0=%%~dp0
EXIT /b
:start
SETLOCAL
CALL :find_dp0

endLocal & goto #_undefined_# 2>NUL || title %%COMSPEC%% & "%s" %%*]]

describe("linker", function()
    ---@module "mason-core.installer.linker"
    local linker
    ---@module "mason-core.platform"
    local platform

    before_each(function()
        package.loaded["mason-core.platform"] = nil
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
            assert.is_true(linker.link(ctx):is_success())

            assert.spy(fs.async.write_file).was_called(0)
            assert.spy(fs.async.symlink).was_called(2)
            assert
                .spy(fs.async.symlink)
                .was_called_with(path.concat { dummy:get_install_path(), "another-executable" }, path.bin_prefix "another-executable")
            assert.spy(fs.async.symlink).was_called_with(
                path.concat { dummy:get_install_path(), "nested", "path", "my-executable" },
                path.bin_prefix "my-executable"
            )
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
            assert.is_true(linker.link(ctx):is_success())

            assert.spy(fs.async.symlink).was_called(0)
            assert.spy(fs.async.write_file).was_called(2)
            assert.spy(fs.async.write_file).was_called_with(
                path.bin_prefix "another-executable.cmd",
                WIN_CMD_SCRIPT:format(path.concat { dummy:get_install_path(), "another-executable" })
            )
            assert.spy(fs.async.write_file).was_called_with(
                path.bin_prefix "my-executable.cmd",
                WIN_CMD_SCRIPT:format(path.concat { dummy:get_install_path(), "nested", "path", "my-executable" })
            )
        end)
    )

    it(
        "should symlink share files",
        async_test(function()
            local dummy = registry.get_package "dummy"
            stub(fs.async, "mkdirp")
            stub(fs.async, "dir_exists")
            stub(fs.async, "file_exists")
            stub(fs.async, "symlink")
            stub(fs.async, "write_file")

            -- mock non-existent dest files
            fs.async.file_exists.on_call_with(path.share_prefix "share-file").returns(false)
            fs.async.file_exists.on_call_with(path.share_prefix(path.concat { "nested", "share-file" })).returns(false)

            fs.async.dir_exists.on_call_with(path.share_prefix()).returns(false)
            fs.async.dir_exists.on_call_with(path.share_prefix "nested/path").returns(false)

            -- mock existent source files
            fs.async.file_exists.on_call_with(path.concat { dummy:get_install_path(), "share-file" }).returns(true)
            fs.async.file_exists
                .on_call_with(path.concat { dummy:get_install_path(), "nested", "path", "to", "share-file" })
                .returns(true)

            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            ctx.links.share["nested/path/share-file"] = path.concat { "nested", "path", "to", "share-file" }
            ctx.links.share["share-file"] = "share-file"

            local result = linker.link(ctx)

            assert.is_true(result:is_success())

            assert.spy(fs.async.write_file).was_called(0)
            assert.spy(fs.async.symlink).was_called(2)
            assert
                .spy(fs.async.symlink)
                .was_called_with(path.concat { dummy:get_install_path(), "share-file" }, path.share_prefix "share-file")
            assert.spy(fs.async.symlink).was_called_with(
                path.concat { dummy:get_install_path(), "nested", "path", "to", "share-file" },
                path.share_prefix "nested/path/share-file"
            )

            assert.spy(fs.async.mkdirp).was_called(2)
            assert.spy(fs.async.mkdirp).was_called_with(path.share_prefix())
            assert.spy(fs.async.mkdirp).was_called_with(path.share_prefix "nested/path")
        end)
    )

    it("should copy share files on Windows", function()
        platform.is.darwin = false
        platform.is.mac = false
        platform.is.linux = false
        platform.is.unix = false
        platform.is.win = true

        local dummy = registry.get_package "dummy"
        stub(fs.async, "mkdirp")
        stub(fs.async, "dir_exists")
        stub(fs.async, "file_exists")
        stub(fs.async, "copy_file")

        -- mock non-existent dest files
        fs.async.file_exists.on_call_with(path.share_prefix "share-file").returns(false)
        fs.async.file_exists.on_call_with(path.share_prefix(path.concat { "nested", "share-file" })).returns(false)

        fs.async.dir_exists.on_call_with(path.share_prefix()).returns(false)
        fs.async.dir_exists.on_call_with(path.share_prefix "nested/path").returns(false)

        -- mock existent source files
        fs.async.file_exists.on_call_with(path.concat { dummy:get_install_path(), "share-file" }).returns(true)
        fs.async.file_exists
            .on_call_with(path.concat { dummy:get_install_path(), "nested", "path", "to", "share-file" })
            .returns(true)

        local handle = InstallHandleGenerator "dummy"
        local ctx = InstallContextGenerator(handle)
        ctx.links.share["nested/path/share-file"] = path.concat { "nested", "path", "to", "share-file" }
        ctx.links.share["share-file"] = "share-file"

        local result = linker.link(ctx)

        assert.is_true(result:is_success())

        assert.spy(fs.async.copy_file).was_called(2)
        assert
            .spy(fs.async.copy_file)
            .was_called_with(path.concat { dummy:get_install_path(), "share-file" }, path.share_prefix "share-file", { excl = true })
        assert.spy(fs.async.copy_file).was_called_with(
            path.concat { dummy:get_install_path(), "nested", "path", "to", "share-file" },
            path.share_prefix "nested/path/share-file",
            { excl = true }
        )

        assert.spy(fs.async.mkdirp).was_called(2)
        assert.spy(fs.async.mkdirp).was_called_with(path.share_prefix())
        assert.spy(fs.async.mkdirp).was_called_with(path.share_prefix "nested/path")
    end)
end)
