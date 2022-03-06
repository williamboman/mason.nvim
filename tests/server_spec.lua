local spy = require "luassert.spy"
local lsp_installer = require "nvim-lsp-installer"
local server = require "nvim-lsp-installer.server"
local a = require "nvim-lsp-installer.core.async"
local context = require "nvim-lsp-installer.installers.context"
local fs = require "nvim-lsp-installer.fs"

local function timestamp()
    local seconds, microseconds = vim.loop.gettimeofday()
    return (seconds * 1000) + math.floor(microseconds / 1000)
end

describe("server", function()
    it(
        "calls registered on_ready handlers upon successful installation",
        async_test(function()
            local on_ready_handler = spy.new()
            local generic_handler = spy.new()

            lsp_installer.on_server_ready(generic_handler)

            local srv = ServerGenerator {
                name = "on_ready_fixture",
                root_dir = server.get_server_root_path "on_ready_fixture",
            }
            srv:on_ready(on_ready_handler)
            srv:install()
            assert.wait_for(function()
                assert.spy(on_ready_handler).was_called(1)
                assert.spy(generic_handler).was_called(1)
                assert.spy(generic_handler).was_called_with(srv)
            end)
            assert.is_true(srv:is_installed())
        end)
    )

    it(
        "doesn't call on_ready handler when server fails installation",
        async_test(function()
            local on_ready_handler = spy.new()
            local generic_handler = spy.new()

            lsp_installer.on_server_ready(generic_handler)

            local srv = FailingServerGenerator {
                name = "on_ready_fixture_failing",
                root_dir = server.get_server_root_path "on_ready_fixture_failing",
            }
            srv:on_ready(on_ready_handler)
            srv:install()
            a.sleep(500)
            assert.spy(on_ready_handler).was_not_called()
            assert.spy(generic_handler).was_not_called()
            assert.is_false(srv:is_installed())
        end)
    )

    it(
        "should remove directories upon installation failure",
        async_test(function()
            local srv = FailingServerGenerator {
                name = "remove_dirs_failure",
                root_dir = server.get_server_root_path "remove_dirs_failure",
                installer = {
                    -- 1. sleep 500ms
                    function(_, callback)
                        vim.defer_fn(function()
                            callback(true)
                        end, 500)
                    end,
                    -- 2. promote install dir
                    context.promote_install_dir(),
                    -- 3. fail
                    function(_, callback)
                        callback(false)
                    end,
                },
            }
            srv:install()

            -- 1. installation started
            a.sleep(50)
            assert.is_true(fs.dir_exists(srv:get_tmp_install_dir()))

            -- 2. install dir promoted
            a.sleep(500)
            assert.is_false(fs.dir_exists(srv:get_tmp_install_dir()))

            -- 3. installation failed
            a.sleep(200)

            assert.is_false(srv:is_installed())
            assert.is_false(fs.dir_exists(srv:get_tmp_install_dir()))
        end)
    )
end)
