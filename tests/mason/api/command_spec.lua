local spy = require "luassert.spy"
local match = require "luassert.match"
local log = require "mason-core.log"

local a = require "mason-core.async"
local api = require "mason.api.command"
local registry = require "mason-registry"

describe(":Mason", function()
    it(
        "should open the UI window",
        async_test(function()
            api.Mason()
            a.scheduler()
            local win = vim.api.nvim_get_current_win()
            local buf = vim.api.nvim_win_get_buf(win)
            assert.equals("mason.nvim", vim.api.nvim_buf_get_option(buf, "filetype"))
        end)
    )
end)

describe(":MasonInstall", function()
    it(
        "should install the provided packages",
        async_test(function()
            local dummy = registry.get_package "dummy"
            local dummy2 = registry.get_package "dummy2"
            spy.on(dummy, "install")
            spy.on(dummy2, "install")
            api.MasonInstall { fargs = { "dummy@1.0.0", "dummy2" } }
            assert.spy(dummy.install).was_called(2) -- twice because it's a metamethod
            assert.spy(dummy.install).was_called_with(match.is_ref(dummy), { version = "1.0.0" })
            assert.spy(dummy2.install).was_called_with(match.is_ref(dummy), { version = nil })
        end)
    )

    it(
        "should open the UI window",
        async_test(function()
            local dummy = registry.get_package "dummy"
            spy.on(dummy, "install")
            api.MasonInstall { fargs = { "dummy" } }
            local win = vim.api.nvim_get_current_win()
            local buf = vim.api.nvim_win_get_buf(win)
            assert.equals("mason.nvim", vim.api.nvim_buf_get_option(buf, "filetype"))
        end)
    )
end)

describe(":MasonUninstall", function()
    it(
        "should uninstall the provided packages",
        async_test(function()
            local dummy = registry.get_package "dummy"
            local dummy2 = registry.get_package "dummy"
            spy.on(dummy, "uninstall")
            spy.on(dummy2, "uninstall")
            api.MasonUninstall { fargs = { "dummy", "dummy2" } }
            assert.spy(dummy.uninstall).was_called(2)
            assert.spy(dummy.uninstall).was_called_with(match.is_ref(dummy))
            assert.spy(dummy.uninstall).was_called_with(match.is_ref(dummy2))
        end)
    )
end)

describe(":MasonLog", function()
    it("should open the log file", function()
        api.MasonLog()
        assert.equals(2, #vim.api.nvim_list_tabpages())
        local win = vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_win_get_buf(win)
        vim.api.nvim_buf_call(buf, function()
            assert.equals(log.outfile, vim.fn.expand "%")
        end)
    end)
end)
