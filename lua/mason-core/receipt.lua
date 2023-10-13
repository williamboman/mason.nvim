local Result = require "mason-core.result"
local fs = require "mason-core.fs"
local path = require "mason-core.path"

local M = {}

---@alias InstallReceiptSchemaVersion
---| '"1.0"'
---| '"1.1"'
---| '"1.2"'

---@alias InstallReceiptSource {type: RegistryPackageSpecSchema, id: string}

---@class InstallReceiptLinks
---@field bin? table<string, string>
---@field share? table<string, string>
---@field opt? table<string, string>

---@class InstallReceipt
---@field public name string
---@field public schema_version InstallReceiptSchemaVersion
---@field public metrics {start_time:integer, completion_time:integer}
---@field public source InstallReceiptSource
---@field public links InstallReceiptLinks
local InstallReceipt = {}
InstallReceipt.__index = InstallReceipt

function InstallReceipt:new(data)
    return setmetatable(data, self)
end

function InstallReceipt.from_json(json)
    return InstallReceipt:new(json)
end

function InstallReceipt:get_name()
    return self.name
end

function InstallReceipt:get_schema_version()
    return self.schema_version
end

---@param version string
function InstallReceipt:is_schema_min(version)
    local semver = require "mason-vendor.semver"
    return semver(self.schema_version) >= semver(version)
end

---@return InstallReceiptSource
function InstallReceipt:get_source()
    if self:is_schema_min "1.2" then
        return self.source
    end
    return self.primary_source --[[@as InstallReceiptSource]]
end

function InstallReceipt:get_links()
    return self.links
end

---@async
---@param dir string
function InstallReceipt:write(dir)
    return Result.pcall(function()
        fs.async.write_file(path.concat { dir, "mason-receipt.json" }, vim.json.encode(self))
    end)
end

---@class InstallReceiptBuilder
---@field links InstallReceiptLinks
local InstallReceiptBuilder = {}
InstallReceiptBuilder.__index = InstallReceiptBuilder

function InstallReceiptBuilder:new()
    ---@type InstallReceiptBuilder
    local instance = {}
    setmetatable(instance, self)
    instance.links = {
        bin = vim.empty_dict(),
        share = vim.empty_dict(),
        opt = vim.empty_dict(),
    }
    return instance
end

---@param name string
function InstallReceiptBuilder:with_name(name)
    self.name = name
    return self
end

---@param source InstallReceiptSource
function InstallReceiptBuilder:with_source(source)
    self.source = source
    return self
end

---@param typ '"bin"' | '"share"' | '"opt"'
---@param name string
---@param rel_path string
function InstallReceiptBuilder:with_link(typ, name, rel_path)
    assert(not self.links[typ][name], ("%s/%s has already been linked."):format(typ, name))
    self.links[typ][name] = rel_path
    return self
end

---@param seconds integer
---@param microseconds integer
local function to_ms(seconds, microseconds)
    return (seconds * 1000) + math.floor(microseconds / 1000)
end

---vim.loop.gettimeofday()
---@param seconds integer
---@param microseconds integer
function InstallReceiptBuilder:with_completion_time(seconds, microseconds)
    self.completion_time = to_ms(seconds, microseconds)
    return self
end

---vim.loop.gettimeofday()
---@param seconds integer
---@param microseconds integer
function InstallReceiptBuilder:with_start_time(seconds, microseconds)
    self.start_time = to_ms(seconds, microseconds)
    return self
end

function InstallReceiptBuilder:build()
    assert(self.name, "name is required")
    assert(self.start_time, "start_time is required")
    assert(self.completion_time, "completion_time is required")
    assert(self.source, "source is required")
    return InstallReceipt:new {
        name = self.name,
        schema_version = "1.2",
        metrics = {
            start_time = self.start_time,
            completion_time = self.completion_time,
        },
        source = self.source,
        links = self.links,
    }
end

M.InstallReceiptBuilder = InstallReceiptBuilder
M.InstallReceipt = InstallReceipt

return M
