local luarocks = require "nvim-lsp-installer.core.managers.luarocks"

describe("luarocks manager", function()
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
