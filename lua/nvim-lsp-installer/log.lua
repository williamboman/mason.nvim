local settings = require "nvim-lsp-installer.settings"

local config = {
    -- Name of the plugin. Prepended to log messages
    name = "lsp-installer",

    -- Should print the output to neovim while running
    -- values: 'sync','async',false
    use_console = false,

    -- Should highlighting be used in console (using echohl)
    highlights = true,

    -- Should write to a file
    use_file = true,

    -- Level configuration
    modes = {
        { name = "trace", hl = "Comment" },
        { name = "debug", hl = "Comment" },
        { name = "info", hl = "None" },
        { name = "warn", hl = "WarningMsg" },
        { name = "error", hl = "ErrorMsg" },
        { name = "fatal", hl = "ErrorMsg" },
    },

    -- Can limit the number of decimals displayed for floats
    float_precision = 0.01,
}

local log = {}

local unpack = unpack or table.unpack

do
    local outfile = string.format("%s/%s.log", vim.api.nvim_call_function("stdpath", { "cache" }), config.name)

    local round = function(x, increment)
        increment = increment or 1
        x = x / increment
        return (x > 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)) * increment
    end

    local make_string = function(...)
        local t = {}
        for i = 1, select("#", ...) do
            local x = select(i, ...)

            if type(x) == "number" and config.float_precision then
                x = tostring(round(x, config.float_precision))
            elseif type(x) == "table" then
                x = vim.inspect(x)
            else
                x = tostring(x)
            end

            t[#t + 1] = x
        end
        return table.concat(t, " ")
    end

    local log_at_level = function(level, level_config, message_maker, ...)
        -- Return early if we're below the current_log_level
        if level < settings.current.log_level then
            return
        end
        local nameupper = level_config.name:upper()

        local msg = message_maker(...)
        local info = debug.getinfo(config.info_level or 2, "Sl")
        local lineinfo = info.short_src .. ":" .. info.currentline

        -- Output to console
        if config.use_console then
            local log_to_console = function()
                local console_string = string.format("[%-6s%s] %s: %s", nameupper, os.date "%H:%M:%S", lineinfo, msg)

                if config.highlights and level_config.hl then
                    vim.cmd(string.format("echohl %s", level_config.hl))
                end

                local split_console = vim.split(console_string, "\n")
                for _, v in ipairs(split_console) do
                    local formatted_msg = string.format("[%s] %s", config.name, vim.fn.escape(v, [["\]]))

                    local ok = pcall(vim.cmd, string.format([[echom "%s"]], formatted_msg))
                    if not ok then
                        vim.api.nvim_out_write(msg .. "\n")
                    end
                end

                if config.highlights and level_config.hl then
                    vim.cmd "echohl NONE"
                end
            end
            if config.use_console == "sync" and not vim.in_fast_event() then
                log_to_console()
            else
                vim.schedule(log_to_console)
            end
        end

        -- Output to log file
        if config.use_file then
            local fp = assert(io.open(outfile, "a"))
            local str = string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, msg)
            fp:write(str)
            fp:close()
        end
    end

    for i, x in ipairs(config.modes) do
        -- log.info("these", "are", "separated")
        log[x.name] = function(...)
            return log_at_level(i, x, make_string, ...)
        end

        -- log.fmt_info("These are %s strings", "formatted")
        log[("fmt_%s"):format(x.name)] = function(...)
            return log_at_level(i, x, function(...)
                local passed = { ... }
                local fmt = table.remove(passed, 1)
                local inspected = {}
                for _, v in ipairs(passed) do
                    table.insert(inspected, vim.inspect(v))
                end
                return string.format(fmt, unpack(inspected))
            end, ...)
        end

        -- log.lazy_info(expensive_to_calculate)
        log[("lazy_%s"):format(x.name)] = function()
            return log_at_level(i, x, function(f)
                return f()
            end)
        end

        -- log.file_info("do not print")
        log[("file_%s"):format(x.name)] = function(vals, override)
            local original_console = config.use_console
            config.use_console = false
            config.info_level = override.info_level
            log_at_level(i, x, make_string, unpack(vals))
            config.use_console = original_console
            config.info_level = nil
        end
    end
end

return log
