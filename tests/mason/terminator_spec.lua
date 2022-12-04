local stub = require "luassert.stub"
local spy = require "luassert.spy"
local a = require "mason-core.async"
local registry = require "mason-registry"
local terminator = require "mason.terminator"
local _ = require "mason-core.functional"
local InstallHandle = require "mason-core.installer.handle"

describe("terminator", function()
    before_each(function()
        terminator.setup()
    end)

    it(
        "should terminate all active handles on nvim exit",
        async_test(function()
            local dummy = registry.get_package "dummy"
            local dummy2 = registry.get_package "dummy2"
            for _, pkg in ipairs { dummy, dummy2 } do
                stub(pkg.spec, "install")
                pkg.spec.install.invokes(function()
                    a.sleep(10000)
                end)
            end

            dummy:install()
            dummy2:install()
            spy.on(InstallHandle, "terminate")

            terminator.terminate()
            a.scheduler()

            assert.spy(InstallHandle.terminate).was_called(2)
        end)
    )

    it(
        "should print warning messages",
        async_test(function()
            spy.on(vim.api, "nvim_echo")
            spy.on(vim.api, "nvim_err_writeln")
            local dummy = registry.get_package "dummy"
            local dummy2 = registry.get_package "dummy2"
            for _, pkg in ipairs { dummy, dummy2 } do
                stub(pkg.spec, "install")
                pkg.spec.install.invokes(function()
                    a.sleep(10000)
                end)
            end

            dummy:install()
            dummy2:install()
            spy.on(InstallHandle, "terminate")

            terminator.terminate()

            assert.spy(vim.api.nvim_echo).was_called(1)
            assert.spy(vim.api.nvim_echo).was_called_with({
                {
                    "[mason.nvim] Neovim is exiting while packages are still installing. Terminating all installations…",
                    "WarningMsg",
                },
            }, true, {})

            a.scheduler()

            assert.spy(vim.api.nvim_err_writeln).was_called(1)
            assert.spy(vim.api.nvim_err_writeln).was_called_with(_.dedent [[
                [mason.nvim] Neovim exited while the following packages were installing. Installation was aborted.
                - dummy
                - dummy2
            ]])
        end)
    )
end)
