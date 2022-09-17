local stub = require "luassert.stub"
local spy = require "luassert.spy"
local match = require "luassert.match"

describe("platform", function()
    local function platform()
        package.loaded["mason-core.platform"] = nil
        return require "mason-core.platform"
    end

    local function stub_uname(uname)
        stub(vim.loop, "os_uname")
        vim.loop.os_uname.returns(uname)
    end

    ---@param libc string
    local function stub_libc(libc)
        stub(os, "execute")
        local exit_code = libc == "musl" and 0 or 1
        -- selene: allow(incorrect_standard_library_use)
        os.execute.on_call_with("ldd --version 2>&1 | grep -q musl").returns(nil, nil, exit_code)
    end

    local function stub_mac()
        stub(vim.fn, "has")
        vim.fn.has.on_call_with("mac").returns(1)
        vim.fn.has.on_call_with("unix").returns(1)
        vim.fn.has.on_call_with("linux").returns(0)
        vim.fn.has.on_call_with(match._).returns(0)
    end

    local function stub_linux()
        stub(vim.fn, "has")
        vim.fn.has.on_call_with("mac").returns(0)
        vim.fn.has.on_call_with("unix").returns(1)
        vim.fn.has.on_call_with("linux").returns(1)
        vim.fn.has.on_call_with(match._).returns(0)
    end

    local function stub_windows()
        stub(vim.fn, "has")
        vim.fn.has.on_call_with("win32").returns(1)
        vim.fn.has.on_call_with(match._).returns(0)
    end

    it("should be able to detect platform and arch", function()
        stub_mac()
        stub_uname { machine = "aarch64" }
        assert.is_true(platform().is.mac_arm64)
        assert.is_false(platform().is.mac_x64)
        assert.is_false(platform().is.nothing)
    end)

    it("should be able to detect macos", function()
        stub_mac()
        assert.is_true(platform().is.mac)
        assert.is_true(platform().is.unix)
        assert.is_false(platform().is.linux)
        assert.is_false(platform().is.win)
    end)

    it("should be able to detect linux", function()
        stub_linux()
        assert.is_false(platform().is.mac)
        assert.is_true(platform().is.unix)
        assert.is_true(platform().is.linux)
        assert.is_false(platform().is.win)
    end)

    it("should be able to detect windows", function()
        stub_windows()
        assert.is_false(platform().is.mac)
        assert.is_false(platform().is.unix)
        assert.is_false(platform().is.linux)
        assert.is_true(platform().is.win)
    end)

    it("should be able to detect correct triple based on libc", function()
        stub_linux()
        stub_uname { machine = "aarch64" }
        stub_libc "musl"
        assert.is_false(platform().is.linux_x64_musl)
        assert.is_false(platform().is.linux_x64_gnu)
        assert.is_true(platform().is.linux_arm64_musl)
        assert.is_false(platform().is.linux_arm64_gnu)
        assert.is_false(platform().is.linux_arm64_gnu)
    end)

    it("should be able to detect correct triple based on sysname", function()
        stub_linux()
        stub_uname { machine = "aarch64", sysname = "OpenBSD" }
        stub_libc "musl"
        assert.is_false(platform().is.linux_x64_musl)
        assert.is_false(platform().is.linux_x64_gnu)
        assert.is_false(platform().is.linux_arm64_gnu)
        assert.is_false(platform().is.linux_arm64_gnu)
        assert.is_true(platform().is.linux_arm64_openbsd)
    end)

    it("should run correct case on linux", function()
        local unix = spy.new()
        local win = spy.new()
        local mac = spy.new()
        local linux = spy.new()

        stub_linux()
        platform().when {
            unix = unix,
            win = win,
            linux = linux,
            mac = mac,
        }
        assert.spy(unix).was_not_called()
        assert.spy(mac).was_not_called()
        assert.spy(win).was_not_called()
        assert.spy(linux).was_called(1)
    end)

    it("should run correct case on mac", function()
        local unix = spy.new()
        local win = spy.new()
        local mac = spy.new()
        local linux = spy.new()

        stub_mac()
        platform().when {
            unix = unix,
            win = win,
            linux = linux,
            mac = mac,
        }
        assert.spy(unix).was_not_called()
        assert.spy(mac).was_called(1)
        assert.spy(win).was_not_called()
        assert.spy(linux).was_not_called()
    end)

    it("should run correct case on windows", function()
        local unix = spy.new()
        local win = spy.new()
        local mac = spy.new()
        local linux = spy.new()

        stub_windows()
        platform().when {
            unix = unix,
            win = win,
            linux = linux,
            mac = mac,
        }
        assert.spy(unix).was_not_called()
        assert.spy(mac).was_not_called()
        assert.spy(win).was_called(1)
        assert.spy(linux).was_not_called()
    end)

    it("should run correct case on mac (unix)", function()
        local unix = spy.new()
        local win = spy.new()

        stub_mac()
        platform().when {
            unix = unix,
            win = win,
        }
        assert.spy(unix).was_called(1)
        assert.spy(win).was_not_called()
    end)

    it("should run correct case on linux (unix)", function()
        local unix = spy.new()
        local win = spy.new()

        stub_linux()
        platform().when {
            unix = unix,
            win = win,
        }
        assert.spy(unix).was_called(1)
        assert.spy(win).was_not_called()
    end)
end)
