local stub = require "luassert.stub"
local match = require "luassert.match"
local spy = require "luassert.spy"
local a = require "mason-core.async"
local registry = require "mason-registry"
local terminator = require "mason-core.terminator"
local _ = require "mason-core.functional"
local InstallHandle = require "mason-core.installer.handle"

describe("terminator", function()
    it(
        "should terminate all active handles on nvim exit",
        async_test(function()
            spy.on(InstallHandle, "terminate")
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
            terminator.terminate(5000)

            a.scheduler()
            assert.spy(InstallHandle.terminate).was_called(2)
        end)
    )

    it(
        "should print warning messages",
        async_test(function()
            spy.on(vim.api, "nvim_echo")
            spy.on(vim.api, "nvim_err_writeln")
            spy.on(InstallHandle, "terminate")
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
            terminator.terminate(5000)

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

    it(
        "should send SIGTERM and then SIGKILL after grace period",
        async_test(function()
            spy.on(InstallHandle, "kill")
            local dummy = registry.get_package "dummy"
            stub(dummy.spec, "install")
            dummy.spec.install.invokes(function(ctx)
                -- your signals have no power here
                ctx.spawn.bash { "-c", "function noop { :; }; trap noop SIGTERM; sleep 999999;" }
            end)

            local handle = dummy:install()

            assert.wait_for(function()
                assert.spy(dummy.spec.install).was_called()
            end)
            terminator.terminate(50)

            assert.wait_for(function()
                assert.spy(InstallHandle.kill).was_called(2)
                assert.spy(InstallHandle.kill).was_called_with(match.is_ref(handle), 15) -- SIGTERM
                assert.spy(InstallHandle.kill).was_called_with(match.is_ref(handle), 9) -- SIGKILL
            end)
        end)
    )
end)
