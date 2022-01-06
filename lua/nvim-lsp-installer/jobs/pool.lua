local log = require "nvim-lsp-installer.log"

local JobExecutionPool = {}
JobExecutionPool.__index = JobExecutionPool

function JobExecutionPool:new(opts)
    return setmetatable({
        size = opts.size,
        _queue = {},
        _supplied_jobs = 0,
        _running_jobs = 0,
    }, JobExecutionPool)
end

function JobExecutionPool:supply(fn)
    self._supplied_jobs = self._supplied_jobs + 1
    self._queue[#self._queue + 1] = setmetatable({
        id = self._supplied_jobs,
    }, {
        __call = function(_, ...)
            fn(...)
        end,
    })
    self:_dequeue()
end

function JobExecutionPool:_dequeue()
    log.fmt_trace("Dequeuing job running_jobs=%s, size=%s", self._running_jobs, self.size)
    if self._running_jobs < self.size and #self._queue > 0 then
        local dequeued = table.remove(self._queue, 1)
        self._running_jobs = self._running_jobs + 1
        log.fmt_trace("Dequeued job job_id=%s, running_jobs=%s, size=%s", dequeued.id, self._running_jobs, self.size)
        dequeued(function()
            log.fmt_trace("Job finished job_id=%s", dequeued.id)
            self._running_jobs = self._running_jobs - 1
            self:_dequeue()
        end)
    end
end

return JobExecutionPool
