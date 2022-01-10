local process = require "nvim-lsp-installer.process"
local VersionCheckResult = require "nvim-lsp-installer.jobs.outdated-servers.version-check-result"
local crates = require "nvim-lsp-installer.core.clients.crates"

---@param output string The `cargo install --list` output.
local function parse_installed_crates(output)
    local installed_crates = {}
    for _, line in ipairs(vim.split(output, "\n")) do
        local name, version = line:match "^(.+)%s+v([.%S]+)[%s:]"
        if name and version then
            installed_crates[name] = version
        end
    end
    return installed_crates
end

---@param server Server
---@param source InstallReceiptSource
---@param on_result fun(result: VersionCheckResult)
local function cargo_check(server, source, on_result)
    local stdio = process.in_memory_sink()
    process.spawn("cargo", {
        args = { "install", "--list", "--root", "." },
        cwd = server.root_dir,
        stdio_sink = stdio.sink,
    }, function(success)
        if not success then
            return on_result(VersionCheckResult.fail(server))
        end
        local installed_crates = parse_installed_crates(table.concat(stdio.buffers.stdout, ""))
        if not installed_crates[source.package] then
            return on_result(VersionCheckResult.fail(server))
        end
        crates.fetch_crate(source.package, function(err, response)
            if err then
                return on_result(VersionCheckResult.fail(server))
            end
            if response.crate.max_stable_version ~= installed_crates[source.package] then
                return on_result(VersionCheckResult.success(server, {
                    {
                        name = source.package,
                        current_version = installed_crates[source.package],
                        latest_version = response.crate.max_stable_version,
                    },
                }))
            else
                return on_result(VersionCheckResult.empty(server))
            end
        end)
    end)
end

return setmetatable({
    parse_installed_crates = parse_installed_crates,
}, {
    __call = function(_, ...)
        return cargo_check(...)
    end,
})
