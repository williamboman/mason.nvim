local a = require "nvim-lsp-installer.core.async"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"

local async_spawn = a.promisify(process.spawn)

local spawn = {
    aliases = {
        npm = platform.is_win and "npm.cmd" or "npm",
    },
}

setmetatable(spawn, {
    __index = function(self, k)
        return function(args)
            local stdio = process.in_memory_sink()
            local cmd_args = {}
            for i, arg in ipairs(args) do
                cmd_args[i] = arg
            end
            ---@type JobSpawnOpts
            local spawn_args = {
                stdio_sink = stdio.sink,
                cwd = args.cwd,
                env = args.env,
                args = cmd_args,
            }
            local cmd = self.aliases[k] or k
            local _, exit_code = async_spawn(cmd, spawn_args)
            assert(exit_code == 0, ("%q exited with an error code: %d."):format(cmd, exit_code))
            return table.concat(stdio.buffers.stdout, ""), table.concat(stdio.buffers.stderr, "")
        end
    end,
})

return spawn
