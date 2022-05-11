---@diagnostic disable: lowercase-global
local mock = require "luassert.mock"
local util = require "luassert.util"

local a = require "nvim-lsp-installer.core.async"
local process = require "nvim-lsp-installer.core.process"
local server = require "nvim-lsp-installer.server"
local Optional = require "nvim-lsp-installer.core.optional"
local receipt = require "nvim-lsp-installer.core.receipt"

function async_test(suspend_fn)
    return function()
        local ok, err = pcall(a.run_blocking, suspend_fn)
        if not ok then
            error(err, util.errorlevel())
        end
    end
end

mockx = {
    just_runs = function() end,
    returns = function(val)
        return function()
            return val
        end
    end,
    throws = function(exception)
        return function()
            error(exception, 2)
        end
    end,
}

function ServerGenerator(opts)
    local name = opts.name or "dummy"
    return server.Server:new(vim.tbl_deep_extend("force", {
        name = name,
        languages = { "dummylang" },
        root_dir = server.get_server_root_path(name),
        homepage = "https://dummylang.org",
        installer = function(ctx)
            ctx.stdio_sink.stdout "Installing dummy!\n"
        end,
    }, opts))
end

function FailingServerGenerator(opts)
    return ServerGenerator(vim.tbl_deep_extend("force", {
        installer = function(ctx)
            ctx.stdio_sink.stdout "Installing failing dummy!\n"
            error "Failed to do something."
        end,
    }, opts))
end

function InstallContextGenerator(opts)
    ---@type InstallContext
    local default_opts = {
        name = "mock",
        fs = mock.new {
            append_file = mockx.just_runs,
            dir_exists = mockx.returns(true),
            file_exists = mockx.returns(true),
        },
        spawn = mock.new {},
        cwd = mock.new {
            get = mockx.returns "/tmp/install-dir",
            set = mockx.just_runs,
        },
        destination_dir = "/opt/install-dir",
        stdio_sink = process.empty_sink(),
        promote_cwd = mockx.just_runs,
        receipt = receipt.InstallReceiptBuilder.new(),
        requested_version = Optional.empty(),
    }
    local merged_opts = vim.tbl_deep_extend("force", default_opts, opts)
    return mock.new(merged_opts)
end
