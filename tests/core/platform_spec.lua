local stub = require "luassert.stub"
local spy = require "luassert.spy"
local match = require "luassert.match"

describe("platform", function()
    local function platform()
        package.loaded["nvim-lsp-installer.core.platform"] = nil
        return require "nvim-lsp-installer.core.platform"
    end

    local function stub_mac(arch)
        arch = arch or "x86_64"
        stub(vim.fn, "has")
        stub(vim.loop, "os_uname")
        vim.loop.os_uname.returns { machine = arch }
        vim.fn.has.on_call_with("mac").returns(1)
        vim.fn.has.on_call_with("unix").returns(1)
        vim.fn.has.on_call_with(match._).returns(0)
    end

    local function stub_linux()
        stub(vim.fn, "has")
        vim.fn.has.on_call_with("mac").returns(0)
        vim.fn.has.on_call_with("unix").returns(1)
        vim.fn.has.on_call_with(match._).returns(0)
    end

    local function stub_windows()
        stub(vim.fn, "has")
        vim.fn.has.on_call_with("win32").returns(1)
        vim.fn.has.on_call_with(match._).returns(0)
    end

    it("should be able to detect platform and arch", function()
        stub_mac "arm64"
        assert.is_true(platform().is.mac_arm64)
        assert.is_false(platform().is.mac_x64)
        assert.is_false(platform().is.nothing)
    end)

    it("should be able to detect macos", function()
        stub_mac()
        assert.is_true(platform().is_mac)
        assert.is_true(platform().is.mac)
        assert.is_true(platform().is_unix)
        assert.is_true(platform().is.unix)
        assert.is_false(platform().is_linux)
        assert.is_false(platform().is.linux)
        assert.is_false(platform().is_win)
        assert.is_false(platform().is.win)
    end)

    it("should be able to detect linux", function()
        stub_linux()
        assert.is_false(platform().is_mac)
        assert.is_false(platform().is.mac)
        assert.is_true(platform().is_unix)
        assert.is_true(platform().is.unix)
        assert.is_true(platform().is_linux)
        assert.is_true(platform().is.linux)
        assert.is_false(platform().is_win)
        assert.is_false(platform().is.win)
    end)

    it("should be able to detect windows", function()
        stub_windows()
        assert.is_false(platform().is_mac)
        assert.is_false(platform().is.mac)
        assert.is_false(platform().is_unix)
        assert.is_false(platform().is.unix)
        assert.is_false(platform().is_linux)
        assert.is_false(platform().is.linux)
        assert.is_true(platform().is_win)
        assert.is_true(platform().is.win)
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
