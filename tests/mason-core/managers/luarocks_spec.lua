local a = require "mason-core.async"
local installer = require "mason-core.installer"
local luarocks = require "mason-core.managers.luarocks"
local path = require "mason-core.path"

describe("luarocks manager", function()
    before_each(function()
        a.run_blocking(installer.create_prefix_dirs)
    end)

    it(
        "should install provided package",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, luarocks.package "lua-cjson")
            assert.spy(ctx.spawn.luarocks).was_called(1)
            assert.spy(ctx.spawn.luarocks).was_called_with {
                "install",
                "--tree",
                path.package_prefix "dummy",
                vim.NIL, -- --dev flag
                vim.NIL, -- --server flag
                "lua-cjson",
                vim.NIL, -- version
            }
        end)
    )

    it(
        "should install provided version",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "1.2.3" })
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, luarocks.package "lua-cjson")
            assert.spy(ctx.spawn.luarocks).was_called(1)
            assert.spy(ctx.spawn.luarocks).was_called_with {
                "install",
                "--tree",
                path.package_prefix "dummy",
                vim.NIL, -- --dev flag
                vim.NIL, -- --server flag
                "lua-cjson",
                "1.2.3",
            }
        end)
    )

    it(
        "should provide --dev flag",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, luarocks.package("lua-cjson", { dev = true }))
            assert.spy(ctx.spawn.luarocks).was_called(1)
            assert.spy(ctx.spawn.luarocks).was_called_with {
                "install",
                "--tree",
                path.package_prefix "dummy",
                "--dev",
                vim.NIL, -- --server flag
                "lua-cjson",
                vim.NIL, -- version
            }
        end)
    )

    it(
        "should provide --server flag",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, luarocks.package("luaformatter", { server = "https://luarocks.org/dev" }))
            assert.spy(ctx.spawn.luarocks).was_called(1)
            assert.spy(ctx.spawn.luarocks).was_called_with {
                "install",
                "--tree",
                path.package_prefix "dummy",
                vim.NIL, -- --dev flag
                "--server=https://luarocks.org/dev",
                "luaformatter",
                vim.NIL, -- version
            }
        end)
    )

    it("should parse outdated luarocks", function()
        assert.same(
            {
                {
                    name = "lua-cjson",
                    installed = "2.1.0-1",
                    available = "2.1.0.6-1",
                    repo = "https://luarocks.org",
                },
                {
                    name = "lua-resty-influx-mufanh",
                    installed = "0.2.1-0",
                    available = "0.2.1-1",
                    repo = "https://luarocks.org",
                },
            },
            luarocks.parse_outdated_rocks [[lua-cjson	2.1.0-1	2.1.0.6-1	https://luarocks.org
lua-resty-influx-mufanh	0.2.1-0	0.2.1-1	https://luarocks.org]]
        )
    end)

    it("should parse listed luarocks", function()
        assert.same(
            {
                {
                    package = "lua-cjson",
                    version = "2.1.0-1",
                    arch = "installed",
                    nrepo = "/my/luarock/loc",
                },
                {
                    package = "lua-resty-http",
                    version = "0.17.0.beta.1-0",
                    arch = "installed",
                    nrepo = "/my/luarock/loc",
                },
                {
                    package = "lua-resty-influx-mufanh",
                    version = "0.2.1-0",
                    arch = "installed",
                    nrepo = "/my/luarock/loc",
                },
            },
            luarocks.parse_installed_rocks [[lua-cjson	2.1.0-1	installed	/my/luarock/loc
lua-resty-http	0.17.0.beta.1-0	installed	/my/luarock/loc
lua-resty-influx-mufanh	0.2.1-0	installed	/my/luarock/loc]]
        )
    end)
end)
