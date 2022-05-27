local M = {}

---@alias InstallReceiptSchemaVersion
---| '"1.0"'
---| '"1.0a"'

---@alias InstallReceiptSourceType
---| '"npm"'
---| '"pip3"'
---| '"gem"'
---| '"go"'
---| '"cargo"'
---| '"opam"'
---| '"dotnet"'
---| '"r_package"'
---| '"unmanaged"'
---| '"system"'
---| '"jdtls"'
---| '"git"'
---| '"github_tag"'
---| '"github_release"'
---| '"github_release_file"'

---@alias InstallReceiptSource {type: InstallReceiptSourceType}

---@class InstallReceiptBuilder
---@field public is_marked_invalid boolean Whether this instance of the builder has been marked as invalid. This is an exception that only apply to a few select servers whose installation is not yet compatible with the receipt schema due to having a too complicated installation structure.
---@field private secondary_sources InstallReceiptSource[]
---@field private epoch_time number
local InstallReceiptBuilder = {}
InstallReceiptBuilder.__index = InstallReceiptBuilder

function InstallReceiptBuilder.new()
    return setmetatable({
        is_marked_invalid = false,
        secondary_sources = {},
    }, InstallReceiptBuilder)
end

function InstallReceiptBuilder:mark_invalid()
    self.is_marked_invalid = true
    return self
end

---@param name string
function InstallReceiptBuilder:with_name(name)
    self.name = name
    return self
end

---@param version InstallReceiptSchemaVersion
function InstallReceiptBuilder:with_schema_version(version)
    self.schema_version = version
    return self
end

---@param source InstallReceiptSource
function InstallReceiptBuilder:with_primary_source(source)
    self.primary_source = source
    return self
end

---@param source InstallReceiptSource
function InstallReceiptBuilder:with_secondary_source(source)
    table.insert(self.secondary_sources, source)
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
    assert(self.schema_version, "schema_version is required")
    assert(self.start_time, "start_time is required")
    assert(self.completion_time, "completion_time is required")
    assert(self.primary_source, "primary_source is required")
    return {
        name = self.name,
        schema_version = self.schema_version,
        metrics = {
            start_time = self.start_time,
            completion_time = self.completion_time,
        },
        primary_source = self.primary_source,
        secondary_sources = self.secondary_sources,
    }
end

---@param type InstallReceiptSourceType
local function package_source(type)
    ---@param package string
    return function(package)
        return { type = type, package = package }
    end
end

InstallReceiptBuilder.npm = package_source "npm"
InstallReceiptBuilder.pip3 = package_source "pip3"
InstallReceiptBuilder.gem = package_source "gem"
InstallReceiptBuilder.go = package_source "go"
InstallReceiptBuilder.dotnet = package_source "dotnet"
InstallReceiptBuilder.cargo = package_source "cargo"
InstallReceiptBuilder.composer = package_source "composer"
InstallReceiptBuilder.r_package = package_source "r_package"
InstallReceiptBuilder.opam = package_source "opam"
InstallReceiptBuilder.luarocks = package_source "luarocks"

InstallReceiptBuilder.unmanaged = { type = "unmanaged" }

---@param repo string
---@param release string
function InstallReceiptBuilder.github_release(repo, release)
    return {
        type = "github_release",
        repo = repo,
        release = release,
    }
end

---@param dependency string
function InstallReceiptBuilder.system(dependency)
    return { type = "system", dependency = dependency }
end

---@param remote_url string
function InstallReceiptBuilder.git_remote(remote_url)
    return { type = "git", remote = remote_url }
end

---@class InstallReceipt
---@field public name string
---@field public schema_version InstallReceiptSchemaVersion
---@field public metrics {start_time:integer, completion_time:integer}
---@field public primary_source InstallReceiptSource
---@field public secondary_sources InstallReceiptSource[]
local InstallReceipt = {}
InstallReceipt.__index = InstallReceipt

function InstallReceipt.new(props)
    return setmetatable(props, InstallReceipt)
end

function InstallReceipt.from_json(json)
    return InstallReceipt.new(json)
end

M.InstallReceiptBuilder = InstallReceiptBuilder
M.InstallReceipt = InstallReceipt

return M
