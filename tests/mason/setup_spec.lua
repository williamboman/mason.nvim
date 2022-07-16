local match = require "luassert.match"
local mason = require "mason"
local path = require "mason-core.path"

describe("mason setup", function()
    it("should enhance the PATH environment", function()
        mason.setup()
        assert.is_true(vim.startswith(vim.env.PATH, path.bin_prefix()))
    end)

    it("should set up user commands", function()
        mason.setup()
        local user_commands = vim.api.nvim_get_commands {}

        assert.is_true(match.tbl_containing {
            bang = false,
            bar = false,
            nargs = "0",
            definition = "Opens mason's UI window.",
        }(user_commands["Mason"]))

        assert.is_true(match.tbl_containing {
            bang = false,
            bar = false,
            definition = "Install one or more packages.",
            nargs = "+",
            complete = "custom",
        }(user_commands["MasonInstall"]))

        assert.is_true(match.tbl_containing {
            bang = false,
            bar = false,
            definition = "Uninstall one or more packages.",
            nargs = "+",
            complete = "custom",
        }(user_commands["MasonUninstall"]))

        assert.is_true(match.tbl_containing {
            bang = false,
            bar = false,
            definition = "Uninstall all packages.",
            nargs = "0",
        }(user_commands["MasonUninstallAll"]))

        assert.is_true(match.tbl_containing {
            bang = false,
            bar = false,
            definition = "Opens the mason.nvim log.",
            nargs = "0",
        }(user_commands["MasonLog"]))
    end)
end)
