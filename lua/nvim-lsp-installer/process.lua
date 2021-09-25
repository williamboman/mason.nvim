local log = require "nvim-lsp-installer.log"
local platform = require "nvim-lsp-installer.platform"
local uv = vim.loop

local M = {}

local function connect_sink(pipe, sink)
    return function(err, data)
        if err then
            -- log.error { "Unexpected error when reading pipe.", err }
        end
        if data ~= nil then
            local lines = vim.split(data, "\n")
            for i = 1, #lines do
                sink(lines[i])
            end
        else
            pipe:read_stop()
            pipe:close()
        end
    end
end

-- We gather the root env immediately, primarily because of E5560.
-- Also, there's no particular reason we need to refresh the environment (yet).
local initial_environ = vim.fn.environ()

function M.extend_path(new_paths)
    local new_path_str = table.concat(new_paths, platform.path_sep)
    if initial_environ["PATH"] then
        return new_path_str .. platform.path_sep .. initial_environ["PATH"]
    end
    return new_path_str
end

function M.graft_env(env)
    local root_env = {}
    for key, val in pairs(initial_environ) do
        root_env[#root_env + 1] = key .. "=" .. val
    end
    for key, val in pairs(env) do
        root_env[#root_env + 1] = key .. "=" .. val
    end
    return root_env
end

function M.spawn(cmd, opts, callback)
    local stdin = uv.new_pipe(false)
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)

    local stdio = { stdin, stdout, stderr }

    -- log.debug { "Spawning", cmd, opts }

    local spawn_opts = {
        env = opts.env,
        stdio = stdio,
        args = opts.args,
        cwd = opts.cwd,
        detached = false,
        hide = true,
    }

    local handle, pid
    handle, pid = uv.spawn(cmd, spawn_opts, function(exit_code, signal)
        local successful = exit_code == 0 and signal == 0
        handle:close()
        if not stdin:is_closing() then
            stdin:close()
        end

        -- ensure all pipes are closed, for I am a qualified plumber
        local check = uv.new_check()
        check:start(function()
            for i = 1, #stdio do
                local pipe = stdio[i]
                if not pipe:is_closing() then
                    return
                end
            end
            check:stop()
            callback(successful)
        end)
    end)

    if handle == nil then
        opts.stdio_sink.stderr(("Failed to spawn process cmd=%s pid=%s"):format(cmd, pid))
        callback(false)
        return nil, nil
    end

    -- log.debug { "Spawned with pid", pid }

    stdout:read_start(connect_sink(stdout, opts.stdio_sink.stdout))
    stderr:read_start(connect_sink(stderr, opts.stdio_sink.stderr))

    return handle, stdio
end

function M.chain(opts)
    local stack = {}
    return {
        run = function(cmd, args)
            stack[#stack + 1] = { cmd = cmd, args = args }
        end,
        spawn = function(callback)
            local function execute(idx)
                local item = stack[idx]
                M.spawn(
                    item.cmd,
                    vim.tbl_deep_extend("force", opts, {
                        args = item.args,
                    }),
                    function(successful)
                        if successful and stack[idx + 1] then
                            -- iterate
                            execute(idx + 1)
                        else
                            -- we done
                            callback(successful)
                        end
                    end
                )
            end

            execute(1)
        end,
    }
end

function M.empty_sink()
    local function noop() end
    return {
        stdout = noop,
        stderr = noop,
    }
end

function M.simple_sink()
    return {
        stdout = vim.schedule_wrap(print),
        stderr = vim.schedule_wrap(vim.api.nvim_err_writeln),
    }
end

-- this prob belongs elsewhere ¯\_(ツ)_/¯
function M.debounced(debounced_fn)
    local queued = false
    local last_arg = nil
    return function(a)
        last_arg = a
        if queued then
            return
        end
        queued = true
        vim.schedule(function()
            debounced_fn(last_arg)
            queued = false
        end)
    end
end

return M
