local spy = require "luassert.spy"
local match = require "luassert.match"
local log = require "mason-core.log"

local a = require "mason-core.async"
local api = require "mason.api.command"
local registry = require "mason-registry"
local Pkg = require "mason-core.package"

describe(":Mason", function()
    it(
        "should open the UI window",
        async_test(function()
            api.Mason()
            a.scheduler()
            local win = vim.api.nvim_get_current_win()
            local buf = vim.api.nvim_win_get_buf(win)
            assert.equals("mason", vim.api.nvim_buf_get_option(buf, "filetype"))
        end)
    )
end)

describe(":MasonInstall", function()
    it(
        "should install the provided packages",
        async_test(function()
            local dummy = registry.get_package "dummy"
            local dummy2 = registry.get_package "dummy2"
            spy.on(Pkg, "install")
            api.MasonInstall { "dummy@1.0.0", "dummy2" }
            assert.spy(Pkg.install).was_called(2)
            assert.spy(Pkg.install).was_called_with(match.is_ref(dummy), { version = "1.0.0" })
            assert
                .spy(Pkg.install)
                .was_called_with(match.is_ref(dummy2), match.tbl_containing { version = match.is_nil() })
        end)
    )

    it(
        "should install provided packages in debug mode",
        async_test(function()
            local dummy = registry.get_package "dummy"
            local dummy2 = registry.get_package "dummy2"
            spy.on(Pkg, "install")
            vim.cmd [[MasonInstall --debug dummy dummy2]]
            assert.spy(Pkg.install).was_called(2)
            assert.spy(Pkg.install).was_called_with(match.is_ref(dummy), { version = nil, debug = true })
            assert.spy(Pkg.install).was_called_with(match.is_ref(dummy2), { version = nil, debug = true })
        end)
    )

    it(
        "should open the UI window",
        async_test(function()
            local dummy = registry.get_package "dummy"
            spy.on(dummy, "install")
            api.MasonInstall { "dummy" }
            local win = vim.api.nvim_get_current_win()
            local buf = vim.api.nvim_win_get_buf(win)
            assert.equals("mason", vim.api.nvim_buf_get_option(buf, "filetype"))
        end)
    )
end)

describe(":MasonUninstall", function()
    it(
        "should uninstall the provided packages",
        async_test(function()
            local dummy = registry.get_package "dummy"
            local dummy2 = registry.get_package "dummy"
            spy.on(Pkg, "uninstall")
            api.MasonUninstall { "dummy", "dummy2" }
            assert.spy(Pkg.uninstall).was_called(2)
            assert.spy(Pkg.uninstall).was_called_with(match.is_ref(dummy))
            assert.spy(Pkg.uninstall).was_called_with(match.is_ref(dummy2))
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
