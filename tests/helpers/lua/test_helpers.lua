---@diagnostic disable: lowercase-global
local mock = require "luassert.mock"
local util = require "luassert.util"

local a = require "nvim-lsp-installer.core.async"
local process = require "nvim-lsp-installer.process"
local server = require "nvim-lsp-installer.server"
local Optional = require "nvim-lsp-installer.core.optional"
local Result = require "nvim-lsp-installer.core.result"
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
    return server.Server:new(vim.tbl_deep_extend("force", {
        name = "dummy",
        languages = { "dummylang" },
        root_dir = server.get_server_root_path "dummy",
        homepage = "https://dummylang.org",
        installer = function(_, callback, ctx)
            ctx.stdio_sink.stdout "Installing dummy!\n"
            callback(true)
        end,
    }, opts))
end

function FailingServerGenerator(opts)
    return ServerGenerator(vim.tbl_deep_extend("force", {
        installer = function(_, callback, ctx)
            ctx.stdio_sink.stdout "Installing failing dummy!\n"
            callback(false)
        end,
    }, opts))
end

function InstallContextGenerator(opts)
    ---@type InstallContext
    local default_opts = {
        fs = mock.new {
            append_file = mockx.just_runs,
            dir_exists = mockx.returns(true),
            file_exists = mockx.returns(true),
        },
        spawn = mock.new {},
        cwd = function()
            return "/tmp/install-dir"
        end,
        promote_cwd = mockx.returns(Result.success()),
        receipt = receipt.InstallReceiptBuilder.new(),
        requested_version = Optional.empty(),
    }
    local merged_opts = vim.tbl_deep_extend("force", default_opts, opts)
    return mock.new(merged_opts)
end
