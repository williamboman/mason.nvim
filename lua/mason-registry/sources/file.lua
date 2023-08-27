local Optional = require "mason-core.optional"
local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local async_control = require "mason-core.async.control"
local async_uv = require "mason-core.async.uv"
local fs = require "mason-core.fs"
local log = require "mason-core.log"
local path = require "mason-core.path"
local spawn = require "mason-core.spawn"
local util = require "mason-registry.sources.util"

local Channel = async_control.Channel

---@class FileRegistrySourceSpec
---@field path string

---@class FileRegistrySource : RegistrySource
---@field spec FileRegistrySourceSpec
---@field root_dir string
---@field buffer { specs: RegistryPackageSpec[], instances: table<string, Package> }?
local FileRegistrySource = {}
FileRegistrySource.__index = FileRegistrySource

---@param spec FileRegistrySourceSpec
function FileRegistrySource.new(spec)
    return setmetatable({
        spec = spec,
    }, FileRegistrySource)
end

function FileRegistrySource:is_installed()
    return self.buffer ~= nil
end

---@return RegistryPackageSpec[]
function FileRegistrySource:get_all_package_specs()
    return _.filter_map(util.map_registry_spec, self:get_buffer().specs)
end

---@param specs RegistryPackageSpec[]
function FileRegistrySource:reload(specs)
    self.buffer = _.assoc("specs", specs, self.buffer or {})
    self.buffer.instances = _.compose(
        _.index_by(_.prop "name"),
        _.map(util.hydrate_package(self.buffer.instances or {}))
    )(self:get_all_package_specs())
    return self.buffer
end

function FileRegistrySource:get_buffer()
    return self.buffer or {
        specs = {},
        instances = {},
    }
end

---@param pkg_name string
---@return Package?
function FileRegistrySource:get_package(pkg_name)
    return self:get_buffer().instances[pkg_name]
end

function FileRegistrySource:get_all_package_names()
    return _.map(_.prop "name", self:get_all_package_specs())
end

function FileRegistrySource:get_installer()
    return Optional.of(_.partial(self.install, self))
end

---@async
function FileRegistrySource:install()
    return Result.try(function(try)
        a.scheduler()
        if vim.fn.executable "yq" ~= 1 then
            return Result.failure "yq is not installed."
        end
        local yq = vim.fn.exepath "yq"

        local registry_dir = vim.fn.expand(self.spec.path) --[[@as string]]
        local packages_dir = path.concat { registry_dir, "packages" }
        if not fs.async.dir_exists(registry_dir) then
            return Result.failure(("Directory %s does not exist."):format(registry_dir))
        end

        if not fs.async.dir_exists(packages_dir) then
            return Result.failure "packages/ directory is missing."
        end

        ---@type ReaddirEntry[]
        local entries = _.filter(_.prop_eq("type", "directory"), fs.async.readdir(packages_dir))

        local channel = Channel.new()
        a.run(function()
            for _, entry in ipairs(entries) do
                channel:send(path.concat { packages_dir, entry.name, "package.yaml" })
            end
            channel:close()
        end, function() end)

        local CONSUMERS_COUNT = 10
        local consumers = {}
        for _ = 1, CONSUMERS_COUNT do
            table.insert(consumers, function()
                local specs = {}
                for package_file in channel:iter() do
                    local yaml_spec = fs.async.read_file(package_file)
                    local spec = vim.json.decode(spawn
                        [yq]({
                            "-o",
                            "json",
                            on_spawn = a.scope(function(_, stdio)
                                local stdin = stdio[1]
                                async_uv.write(stdin, yaml_spec)
                                async_uv.shutdown(stdin)
                                async_uv.close(stdin)
                            end),
                        })
                        :get_or_throw(("Failed to parse %s."):format(package_file)).stdout)

                    specs[#specs + 1] = spec
                end
                return specs
            end)
        end

        local specs = _.reduce(vim.list_extend, {}, _.table_pack(a.wait_all(consumers)))
        return specs
    end)
        :on_success(function(specs)
            self:reload(specs)
        end)
        :on_failure(function(err)
            log.fmt_error("Failed to install registry %s. %s", self, err)
        end)
end

function FileRegistrySource:get_display_name()
    if self:is_installed() then
        return ("local: %s"):format(self.spec.path)
    else
        return ("local: %s [uninstalled]"):format(self.spec.path)
    end
end

function FileRegistrySource:__tostring()
    return ("FileRegistrySource(path=%s)"):format(self.spec.path)
end

return FileRegistrySource
