local stub = require "luassert.stub"
local fetch = require "nvim-lsp-installer.core.fetch"
local spawn = require "nvim-lsp-installer.core.spawn"
local Result = require "nvim-lsp-installer.core.result"

describe("fetch", function()
    it(
        "should exhaust all candidates",
        async_test(function()
            stub(spawn, "wget")
            stub(spawn, "curl")
            spawn.wget.returns(Result.failure "wget failure")
            spawn.curl.returns(Result.failure "curl failure")

            local result = fetch "https://api.github.com"
            assert.is_true(result:is_failure())
            assert.spy(spawn.wget).was_called(1)
            assert.spy(spawn.curl).was_called(1)
            assert.spy(spawn.wget).was_called_with {
                {
                    "--header",
                    "User-Agent: nvim-lsp-installer (+https://github.com/williamboman/nvim-lsp-installer)",
                },
                "-nv",
                "-O",
                "-",
                "https://api.github.com",
            }
            assert.spy(spawn.curl).was_called_with {
                { "-H", "User-Agent: nvim-lsp-installer (+https://github.com/williamboman/nvim-lsp-installer)" },
                "-fsSL",
                vim.NIL,
                "https://api.github.com",
            }
        end)
    )

    it(
        "should return stdout",
        async_test(function()
            stub(spawn, "wget")
            spawn.wget.returns(Result.success {
                stdout = [[{"data": "here"}]],
            })
            local result = fetch "https://api.github.com/data"
            assert.is_true(result:is_success())
            assert.equals([[{"data": "here"}]], result:get_or_throw())
        end)
    )

    it(
        "should respect out_file opt",
        async_test(function()
            stub(spawn, "wget")
            stub(spawn, "curl")
            spawn.wget.returns(Result.failure "wget failure")
            spawn.curl.returns(Result.failure "curl failure")
            fetch("https://api.github.com/data", { out_file = "/test.json" })

            assert.spy(spawn.wget).was_called_with {
                {
                    "--header",
                    "User-Agent: nvim-lsp-installer (+https://github.com/williamboman/nvim-lsp-installer)",
                },
                "-nv",
                "-O",
                "/test.json",
                "https://api.github.com/data",
            }

            assert.spy(spawn.curl).was_called_with {
                { "-H", "User-Agent: nvim-lsp-installer (+https://github.com/williamboman/nvim-lsp-installer)" },
                "-fsSL",
                { "-o", "/test.json" },
                "https://api.github.com/data",
            }
        end)
    )
end)
