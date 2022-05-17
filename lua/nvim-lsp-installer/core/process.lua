local log = require "nvim-lsp-installer.log"
local _ = require "nvim-lsp-installer.core.functional"
local platform = require "nvim-lsp-installer.core.platform"
local uv = vim.loop

---@alias luv_pipe any
---@alias luv_handle any

---@class StdioSink
---@field stdout fun(chunk: string)
---@field stderr fun(chunk: string)

local M = {}

---@param pipe luv_pipe
---@param sink fun(chunk: string)
local function connect_sink(pipe, sink)
    ---@param err string | nil
    ---@param data string | nil
    return function(err, data)
        if err then
            log.error("Unexpected error when reading pipe.", err)
        end
        if data ~= nil then
            sink(data)
        else
            pipe:read_stop()
            pipe:close()
        end
    end
end

-- We gather the root env immediately, primarily because of E5560.
-- Also, there's no particular reason we need to refresh the environment (yet).
local initial_environ = vim.fn.environ()

---@param new_paths string[] @A list of paths to prepend the existing PATH with.
function M.extend_path(new_paths)
    local new_path_str = table.concat(new_paths, platform.path_sep)
    return ("%s%s%s"):format(new_path_str, platform.path_sep, initial_environ.PATH or "")
end

---Merges the provided env param with the user's full environent. Provided env has precedence.
---@param env table<string, string>
---@param excluded_var_names string[]|nil
function M.graft_env(env, excluded_var_names)
    local excluded_var_names_set = excluded_var_names and _.set_of(excluded_var_names) or {}
    local merged_env = {}
    for key, val in pairs(initial_environ) do
        if not excluded_var_names_set[key] and env[key] == nil then
            merged_env[#merged_env + 1] = key .. "=" .. val
        end
    end
    for key, val in pairs(env) do
        if not excluded_var_names_set[key] then
            merged_env[#merged_env + 1] = key .. "=" .. val
        end
    end
    return merged_env
end

---@param env_list string[]
local function sanitize_env_list(env_list)
    local sanitized_list = {}
    for __, env in ipairs(env_list) do
        local safe_envs = {
            "GO111MODULE",
            "GOBIN",
            "GOPATH",
            "PATH",
            "GEM_HOME",
            "GEM_PATH",
        }
        local is_safe_env = _.any(function(safe_env)
            return env:find(safe_env .. "=") == 1
        end, safe_envs)
        if is_safe_env then
            sanitized_list[#sanitized_list + 1] = env
        else
            local idx = env:find "="
            sanitized_list[#sanitized_list + 1] = env:sub(1, idx) .. "<redacted>"
        end
    end
    return sanitized_list
end

---@alias JobSpawnCallback fun(success: boolean, exit_code: integer)

---@class JobSpawnOpts
---@field env string[] @List of "key=value" string.
---@field args string[]
---@field cwd string
---@field stdio_sink StdioSink

---@param cmd string @The command/executable.
---@param opts JobSpawnOpts
---@param callback JobSpawnCallback
---@return luv_handle,luv_pipe[]|nil @Returns the job handle and the stdio array on success, otherwise returns nil.
function M.spawn(cmd, opts, callback)
    local stdin = uv.new_pipe(false)
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)

    local stdio = { stdin, stdout, stderr }

    local spawn_opts = {
        env = opts.env,
        stdio = stdio,
        args = opts.args,
        cwd = opts.cwd,
        detached = false,
        hide = true,
    }

    log.lazy_debug(function()
        local sanitized_env = opts.env and sanitize_env_list(opts.env) or nil
        return "Spawning cmd=%s, spawn_opts=%s",
            cmd,
            {
                args = opts.args,
                cwd = opts.cwd,
                env = sanitized_env,
            }
    end)

    local handle, pid_or_err
    handle, pid_or_err = uv.spawn(cmd, spawn_opts, function(exit_code, signal)
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
            callback(successful, exit_code)
        end)

        log.fmt_debug("Job pid=%s exited with exit_code=%s, signal=%s", pid_or_err, exit_code, signal)
    end)

    if handle == nil then
        log.fmt_error("Failed to spawn process. cmd=%s, err=%s", cmd, pid_or_err)
        if type(pid_or_err) == "string" and pid_or_err:find "ENOENT" == 1 then
            opts.stdio_sink.stderr(("Could not find executable %q in path.\n"):format(cmd))
        else
            opts.stdio_sink.stderr(("Failed to spawn process cmd=%s err=%s\n"):format(cmd, pid_or_err))
        end
        callback(false)
        return nil, nil
    end

    log.debug("Spawned with pid", pid_or_err)

    stdout:read_start(connect_sink(stdout, opts.stdio_sink.stdout))
    stderr:read_start(connect_sink(stderr, opts.stdio_sink.stderr))

    return handle, stdio
end

---@param opts JobSpawnOpts @The job spawn opts to apply in every job in this "chain".
function M.chain(opts)
    local jobs = {}
    return {
        ---@param cmd string
        ---@param args string[]
        run = function(cmd, args)
            jobs[#jobs + 1] = M.lazy_spawn(
                cmd,
                vim.tbl_deep_extend("force", opts, {
                    args = args,
                })
            )
        end,
        ---@param callback JobSpawnCallback
        spawn = function(callback)
            local function execute(idx)
                local ok, err = pcall(jobs[idx], function(successful)
                    if successful and jobs[idx + 1] then
                        -- iterate
                        execute(idx + 1)
                    else
                        -- we done
                        callback(successful)
                    end
                end)
                if not ok then
                    log.fmt_error("Chained job failed to execute. Error=%s", tostring(err))
                    callback(false)
                end
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
        stdout = vim.schedule_wrap(vim.api.nvim_out_write),
        stderr = vim.schedule_wrap(vim.api.nvim_err_write),
    }
end

function M.in_memory_sink()
    local buffers = { stdout = {}, stderr = {} }
    return {
        buffers = buffers,
        sink = {
            stdout = function(chunk)
                buffers.stdout[#buffers.stdout + 1] = chunk
            end,
            stderr = function(chunk)
                buffers.stderr[#buffers.stderr + 1] = chunk
            end,
        },
    }
end

--- This probably belongs elsewhere ¯\_(ツ)_/¯
---@generic T
---@param debounced_fn fun(arg1: T)
---@return fun(arg1: T)
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
            last_arg = nil
        end)
    end
end

---@alias LazyJob fun(callback: JobSpawnCallback)

---@param cmd string
---@param opts JobSpawnOpts
function M.lazy_spawn(cmd, opts)
    ---@param callback JobSpawnCallback
    return function(callback)
        return M.spawn(cmd, opts, callback)
    end
end

---@class JobAttemptOpts
---@field jobs LazyJob[]
---@field on_finish JobSpawnCallback
---@field on_iterate fun()

---@param opts JobAttemptOpts
function M.attempt(opts)
    local jobs, on_finish, on_iterate = opts.jobs, opts.on_finish, opts.on_iterate
    if #jobs == 0 then
        error "process.attempt(...) needs at least one job."
    end

    local spawn, on_job_exit

    on_job_exit = function(cur_idx, success)
        if success then
            -- this job succeeded. exit early
            on_finish(true)
        elseif jobs[cur_idx + 1] then
            -- iterate
            if on_iterate then
                on_iterate()
            end
            log.debug "Previous job failed, attempting next."
            spawn(cur_idx + 1)
        else
            -- we exhausted all jobs without success
            log.debug "All jobs failed."
            on_finish(false)
        end
    end

    spawn = function(idx)
        local ok, err = pcall(jobs[idx], function(success)
            on_job_exit(idx, success)
        end)
        if not ok then
            log.fmt_error("Job failed to execute. Error=%s", tostring(err))
            on_job_exit(idx, false)
            on_finish(false)
        end
    end

    spawn(1)
end

return M
