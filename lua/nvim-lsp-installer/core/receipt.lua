local M = {}

---@alias InstallerReceiptSource table

---@class InstallReceiptBuilder
---@field private secondary_sources InstallerReceiptSource[]
---@field private epoch_time number
local InstallReceiptBuilder = {}
InstallReceiptBuilder.__index = InstallReceiptBuilder

function InstallReceiptBuilder.new()
    return setmetatable({
        secondary_sources = {},
    }, InstallReceiptBuilder)
end

---@param name string
function InstallReceiptBuilder:with_name(name)
    self.name = name
    return self
end

---@alias InstallerReceiptSchemaVersion
---| '"1.0"'

---@param version InstallerReceiptSchemaVersion
function InstallReceiptBuilder:with_schema_version(version)
    self.schema_version = version
    return self
end

---@param source InstallerReceiptSource
function InstallReceiptBuilder:with_primary_source(source)
    self.primary_source = source
    return self
end

---@param source InstallerReceiptSource
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

---@param type string
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

InstallReceiptBuilder.unmanaged = { type = "unmanaged" }

---@param dependency string
function InstallReceiptBuilder.system(dependency)
    return { type = "system", dependency = dependency }
end

---@param remote_url string
---@param revision string
function InstallReceiptBuilder.git_remote(remote_url, revision)
    return { type = "git", remote = remote_url, revision = revision }
end

---@param ctx ServerInstallContext
---@param opts UseGithubReleaseOpts|nil
function InstallReceiptBuilder.github_release_file(ctx, opts)
    opts = opts or {}
    return {
        type = "github_release_file",
        repo = ctx.github_repo,
        file = ctx.github_release_file,
        release = ctx.requested_server_version,
        tag_name_pattern = opts.tag_name_pattern,
    }
end

function InstallReceiptBuilder.github_tag(ctx)
    return {
        type = "github_tag",
        repo = ctx.github_repo,
        tag = ctx.requested_server_version,
    }
end

M.InstallReceiptBuilder = InstallReceiptBuilder

return M
