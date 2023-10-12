local InstallHandle = require "mason-core.installer.handle"
local InstallLocation = require "mason-core.installer.location"
local InstallRunner = require "mason-core.installer.runner"
local fs = require "mason-core.fs"
local match = require "luassert.match"
local spy = require "luassert.spy"
local stub = require "luassert.stub"
local Semaphore = require("mason-core.async.control").Semaphore
local a = require "mason-core.async"
local registry = require "mason-registry"

describe("install runner ::", function()
    local dummy = registry.get_package "dummy"
    local dummy2 = registry.get_package "dummy2"

    local snapshot

    before_each(function()
        snapshot = assert.snapshot()
    end)

    after_each(function()
        snapshot:revert()
    end)

    before_each(function()
        dummy:uninstall()
        dummy2:uninstall()
    end)

    describe("locking ::", function()
        it("should respect semaphore locks", function()
            local semaphore = Semaphore.new(1)
            local location = InstallLocation.global()
            local dummy_handle = InstallHandle.new(dummy)
            local runner_1 = InstallRunner.new(location, dummy_handle, semaphore)
            local runner_2 = InstallRunner.new(location, InstallHandle.new(dummy2), semaphore)

            stub(dummy.spec.source, "install", function()
                a.sleep(10000)
            end)
            spy.on(dummy2.spec.source, "install")

            runner_1:execute {}
            runner_2:execute {}

            assert.wait(function()
                assert.spy(dummy.spec.source.install).was_called(1)
                assert.spy(dummy2.spec.source.install).was_not_called()
            end)

            dummy_handle:terminate()

            assert.wait(function()
                assert.spy(dummy2.spec.source.install).was_called(1)
            end)
        end)

        it("should write lockfile", function()
            local semaphore = Semaphore.new(1)
            local location = InstallLocation.global()
            local dummy_handle = InstallHandle.new(dummy)
            local runner = InstallRunner.new(location, dummy_handle, semaphore)

            spy.on(fs.async, "write_file")

            runner:execute {}

            assert.wait(function()
                assert.spy(fs.async.write_file).was_called_with(location:lockfile(dummy.name), vim.fn.getpid())
            end)
        end)

        it("should abort installation if installation lock exists", function()
            local semaphore = Semaphore.new(1)
            local location = InstallLocation.global()
            local dummy_handle = InstallHandle.new(dummy)
            local runner = InstallRunner.new(location, dummy_handle, semaphore)

            stub(fs.async, "file_exists")
            stub(fs.async, "read_file")
            fs.async.file_exists.on_call_with(location:lockfile(dummy.name)).returns(true)
            fs.async.read_file.on_call_with(location:lockfile(dummy.name)).returns "1337"

            local callback = spy.new()
            runner:execute({}, callback)

            assert.wait(function()
                assert.spy(callback).was_called()
                assert.spy(callback).was_called_with(
                    false,
                    "Lockfile exists, installation is already running in another process (pid: 1337). Run with :MasonInstall --force to bypass."
                )
            end)
        end)

        it("should not abort installation if installation lock exists with force=true", function()
            local semaphore = Semaphore.new(1)
            local location = InstallLocation.global()
            local dummy_handle = InstallHandle.new(dummy)
            local runner = InstallRunner.new(location, dummy_handle, semaphore)

            stub(fs.async, "file_exists")
            stub(fs.async, "read_file")
            fs.async.file_exists.on_call_with(location:lockfile(dummy.name)).returns(true)
            fs.async.read_file.on_call_with(location:lockfile(dummy.name)).returns "1337"

            local callback = spy.new()
            runner:execute({ force = true }, callback)

            assert.wait(function()
                assert.spy(callback).was_called()
                assert.spy(callback).was_called_with(true, nil)
            end)
        end)

        it("should release lock after successful installation", function()
            local semaphore = Semaphore.new(1)
            local location = InstallLocation.global()
            local dummy_handle = InstallHandle.new(dummy)
            local runner = InstallRunner.new(location, dummy_handle, semaphore)

            local callback = spy.new()
            runner:execute({}, callback)

            assert.wait(function()
                assert.is_true(fs.sync.file_exists(location:lockfile(dummy.name)))
            end)
            assert.wait(function()
                assert.spy(callback).was_called()
            end)
            assert.is_false(fs.sync.file_exists(location:lockfile(dummy.name)))
        end)
    end)

    it("should initialize install location", function()
        local location = InstallLocation.global()
        local runner = InstallRunner.new(location, InstallHandle.new(registry.get_package "dummy"), Semaphore.new(1))

        spy.on(location, "initialize")

        runner:execute {}

        assert.wait(function()
            assert.spy(location.initialize).was_called(1)
        end)
    end)

    describe("receipt ::", function()
        it("should write receipt", function()
            local location = InstallLocation.global()
            local runner =
                InstallRunner.new(location, InstallHandle.new(registry.get_package "dummy"), Semaphore.new(1))

            runner:execute {}

            assert.wait(function()
                local receipt_file = location:package "dummy/mason-receipt.json"
                assert.is_true(fs.sync.file_exists(receipt_file))
                assert.is_true(match.tbl_containing {
                    name = "dummy",
                    schema_version = "1.2",
                    metrics = match.tbl_containing {
                        completion_time = match.is_number(),
                        start_time = match.is_number(),
                    },
                    source = match.same {
                        id = "pkg:mason/dummy@1.0.0",
                        type = "registry+v1",
                    },
                    links = match.same {
                        bin = {},
                        opt = {},
                        share = {},
                    },
                }(vim.json.decode(fs.sync.read_file(receipt_file))))
            end)
        end)
    end)

    it("should emit failures", function()
        local registry_spy = spy.new()
        local package_spy = spy.new()
        registry:once("package:install:failed", registry_spy)
        dummy:once("install:failed", package_spy)

        local location = InstallLocation.global()
        local handle = InstallHandle.new(registry.get_package "dummy")
        local runner = InstallRunner.new(location, handle, Semaphore.new(1))

        stub(dummy.spec.source, "install", function()
            error("I've made a mistake.", 0)
        end)

        local callback = spy.new()
        runner:execute({}, callback)

        assert.wait(function()
            assert.spy(registry_spy).was_called(1)
            assert.spy(registry_spy).was_called_with(match.is_ref(dummy), match.is_ref(handle), "I've made a mistake.")
            assert.spy(package_spy).was_called(1)
            assert.spy(package_spy).was_called_with(match.is_ref(handle), "I've made a mistake.")

            assert.spy(callback).was_called(1)
            assert.spy(callback).was_called_with(false, "I've made a mistake.")
        end, 10)
    end)

    it("should terminate installation", function()
        local location = InstallLocation.global()
        local handle = InstallHandle.new(registry.get_package "dummy")
        local runner = InstallRunner.new(location, handle, Semaphore.new(1))

        local capture = spy.new()
        stub(dummy.spec.source, "install", function()
            capture()
            handle:terminate()
            a.sleep(0)
            capture()
        end)

        local callback = spy.new()

        runner:execute({}, callback)

        assert.wait(function()
            assert.spy(callback).was_called(1)
            assert.spy(callback).was_called_with(false, "Installation was aborted.")

            assert.spy(capture).was_called(1)
        end)
    end)

    it("should write debug logs when debug=true", function()
        local location = InstallLocation.global()
        local handle = InstallHandle.new(registry.get_package "dummy")
        local runner = InstallRunner.new(location, handle, Semaphore.new(1))

        stub(dummy.spec.source, "install", function(ctx)
            ctx.stdio_sink.stdout "Hello "
            ctx.stdio_sink.stderr "world!"
        end)

        local callback = spy.new()
        runner:execute({ debug = true }, callback)

        assert.wait(function()
            assert.spy(callback).was_called()
            assert.spy(callback).was_called_with(true, nil)
        end)
        assert.is_true(fs.sync.file_exists(location:package "dummy/mason-debug.log"))
        assert.equals("Hello world!", fs.sync.read_file(location:package "dummy/mason-debug.log"))
    end)

    it("should not retain installation directory on failure", function()
        local location = InstallLocation.global()
        local handle = InstallHandle.new(registry.get_package "dummy")
        local runner = InstallRunner.new(location, handle, Semaphore.new(1))

        stub(dummy.spec.source, "install", function(ctx)
            ctx.stdio_sink.stderr "Something will go terribly wrong.\n"
            error("This went terribly wrong.", 0)
        end)

        local callback = spy.new()
        runner:execute({}, callback)

        assert.wait(function()
            assert.spy(callback).was_called()
            assert.spy(callback).was_called_with(false, "This went terribly wrong.")
        end)
        assert.is_false(fs.sync.dir_exists(location:staging "dummy"))
        assert.is_false(fs.sync.dir_exists(location:package "dummy"))
    end)

    it("should retain installation directory on failure and debug=true", function()
        local location = InstallLocation.global()
        local handle = InstallHandle.new(registry.get_package "dummy")
        local runner = InstallRunner.new(location, handle, Semaphore.new(1))

        stub(dummy.spec.source, "install", function(ctx)
            ctx.stdio_sink.stderr "Something will go terribly wrong.\n"
            error("This went terribly wrong.", 0)
        end)

        local callback = spy.new()
        runner:execute({ debug = true }, callback)

        assert.wait(function()
            assert.spy(callback).was_called()
            assert.spy(callback).was_called_with(false, "This went terribly wrong.")
        end)
        assert.is_true(fs.sync.dir_exists(location:staging "dummy"))
        assert.equals(
            "Something will go terribly wrong.\nThis went terribly wrong.\n",
            fs.sync.read_file(location:staging "dummy/mason-debug.log")
        )
    end)
end)
