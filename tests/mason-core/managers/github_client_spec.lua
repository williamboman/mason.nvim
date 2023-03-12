local Result = require "mason-core.result"
local client = require "mason-core.managers.github.client"
local spawn = require "mason-core.spawn"
local stub = require "luassert.stub"

describe("github client", function()
    it("should provide query parameters in api calls", function()
        stub(spawn, "gh")
        spawn.gh.returns(Result.success { stdout = "response data" })
        client.api_call("repos/some/repo", {
            params = {
                page = 23,
                page_limit = 82,
            },
        })
        assert.spy(spawn.gh).was_called(1)
        assert.spy(spawn.gh).was_called_with {
            "api",
            "repos/some/repo?page=23&page_limit=82",
            env = { CLICOLOR_FORCE = 0 },
        }
    end)
end)
