local mason = require "mason"
local match = require "luassert.match"
local path = require "mason-core.path"
local settings = require "mason.settings"

describe("mason setup", function()
    before_each(function()
        vim.env.MASON = nil
        vim.env.PATH = "/usr/local/bin:/usr/bin"
        settings.set(settings._DEFAULT_SETTINGS)
    end)

    it("should enhance the PATH environment", function()
        mason.setup()
        assert.equals(("%s:/usr/local/bin:/usr/bin"):format(path.bin_prefix()), vim.env.PATH)
    end)

    it("should prepend the PATH environment", function()
        mason.setup { PATH = "prepend" }
        assert.equals(("%s:/usr/local/bin:/usr/bin"):format(path.bin_prefix()), vim.env.PATH)
    end)

    it("should append PATH", function()
        mason.setup { PATH = "append" }
        assert.equals(("/usr/local/bin:/usr/bin:%s"):format(path.bin_prefix()), vim.env.PATH)
    end)

    it("shouldn't modify PATH", function()
        local PATH = vim.env.PATH
        mason.setup { PATH = "skip" }
        assert.equals(PATH, vim.env.PATH)
    end)

    it("should set MASON env", function()
        assert.is_nil(vim.env.MASON)
        mason.setup()
        assert.equals(vim.fn.expand "~/.local/share/nvim/mason", vim.env.MASON)
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
            complete = "<Lua function>",
        }(user_commands["MasonInstall"]))

        assert.is_true(match.tbl_containing {
            bang = false,
            bar = false,
            definition = "Uninstall one or more packages.",
            nargs = "+",
            complete = "<Lua function>",
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

    it("should set the has_setup flag", function()
        package.loaded["mason"] = nil
        local mason = require "mason"
        assert.is_false(mason.has_setup)
        mason.setup()
        assert.is_true(mason.has_setup)
    end)
end)
