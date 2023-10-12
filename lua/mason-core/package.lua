local EventEmitter = require "mason-core.EventEmitter"
local InstallLocation = require "mason-core.installer.location"
local InstallRunner = require "mason-core.installer.runner"
local Optional = require "mason-core.optional"
local Purl = require "mason-core.purl"
local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local fs = require "mason-core.fs"
local log = require "mason-core.log"
local path = require "mason-core.path"
local registry = require "mason-registry"
local settings = require "mason.settings"
local Semaphore = require("mason-core.async.control").Semaphore

---@class Package : EventEmitter
---@field name string
---@field spec RegistryPackageSpec
---@field private handle InstallHandle The currently associated handle.
local Package = setmetatable({}, { __index = EventEmitter })

---@param package_identifier string
---@return string, string?
Package.Parse = function(package_identifier)
    local name, version = unpack(vim.split(package_identifier, "@"))
    return name, version
end

---@alias PackageLanguage string

---@type table<PackageLanguage, PackageLanguage>
Package.Lang = setmetatable({}, {
    __index = function(s, lang)
        s[lang] = lang
        return s[lang]
    end,
})

---@enum PackageCategory
Package.Cat = {
    Compiler = "Compiler",
    Runtime = "Runtime",
    DAP = "DAP",
    LSP = "LSP",
    Linter = "Linter",
    Formatter = "Formatter",
}

---@alias PackageLicense string

---@type table<PackageLicense, PackageLicense>
Package.License = setmetatable({}, {
    __index = function(s, license)
        s[license] = license
        return s[license]
    end,
})

local PackageMt = { __index = Package }

---@class RegistryPackageSourceVersionOverride : RegistryPackageSource
---@field constraint string

---@class RegistryPackageSource
---@field id string PURL-compliant identifier.
---@field version_overrides? RegistryPackageSourceVersionOverride[]

---@class RegistryPackageSchemas
---@field lsp string?

---@class RegistryPackageDeprecation
---@field since string
---@field message string

---@alias RegistryPackageSpecSchema
--- | '"registry+v1"'

---@class RegistryPackageSpec
---@field schema RegistryPackageSpecSchema
---@field name string
---@field description string
---@field homepage string
---@field licenses string[]
---@field languages string[]
---@field categories string[]
---@field source RegistryPackageSource
---@field deprecation RegistryPackageDeprecation?
---@field schemas RegistryPackageSchemas?
---@field bin table<string, string>?
---@field share table<string, string>?
---@field opt table<string, string>?

---@param spec RegistryPackageSpec
function Package.new(spec)
    vim.validate {
        schema = { spec.schema, "s" },
        name = { spec.name, "s" },
        description = { spec.description, "s" },
        homepage = { spec.homepage, "s" },
        licenses = { spec.licenses, "t" },
        categories = { spec.categories, "t" },
        languages = { spec.languages, "t" },
        source = { spec.source, "t" },
        bin = { spec.bin, { "t", "nil" } },
        share = { spec.share, { "t", "nil" } },
    }

    return EventEmitter.init(setmetatable({
        name = spec.name, -- for convenient access
        spec = spec,
    }, PackageMt))
end

function Package:new_handle()
    self:get_handle():if_present(function(handle)
        assert(handle:is_closed(), "Cannot create new handle because existing handle is not closed.")
    end)
    log.fmt_trace("Creating new handle for %s", self)
    local InstallationHandle = require "mason-core.installer.handle"
    local handle = InstallationHandle.new(self)
    self.handle = handle

    -- Ideally we'd decouple this and leverage Mason's event system, but to allow loading as little as possible during
    -- setup (i.e. not load modules related to Mason's event system) of the mason.nvim plugin we explicitly call into
    -- terminator here.
    require("mason-core.terminator").register(handle)

    self:emit("handle", handle)
    registry:emit("package:handle", self, handle)

    return handle
end

---@alias PackageInstallOpts { version?: string, debug?: boolean, target?: string, force?: boolean, strict?: boolean }

-- TODO this needs to be elsewhere
local semaphore = Semaphore.new(settings.current.max_concurrent_installers)

function Package:is_installing()
    return self:get_handle()
        :map(
            ---@param handle InstallHandle
            function(handle)
                return not handle:is_closed()
            end
        )
        :or_else(false)
end

---@param opts? PackageInstallOpts
---@param callback? fun(success: boolean, result: any)
---@return InstallHandle
function Package:install(opts, callback)
    opts = opts or {}
    assert(not self:is_installing(), "Package is already installing.")
    local handle = self:new_handle()
    local runner = InstallRunner.new(InstallLocation.global(), handle, semaphore)
    runner:execute(opts, callback)
    return handle
end

---@return boolean
function Package:uninstall()
    return self:get_receipt()
        :map(function(receipt)
            self:unlink(receipt)
            self:emit("uninstall:success", receipt)
            registry:emit("package:uninstall:success", self, receipt)
            return true
        end)
        :or_else(false)
end

---@private
---@param receipt InstallReceipt
function Package:unlink(receipt)
    log.fmt_trace("Unlinking %s", self)
    local install_path = self:get_install_path()

    -- 1. Unlink
    local linker = require "mason-core.installer.linker"
    linker.unlink(self, receipt, InstallLocation.global()):get_or_throw()

    -- 2. Remove installation artifacts
    fs.sync.rmrf(install_path)
end

function Package:is_installed()
    return registry.is_installed(self.name)
end

function Package:get_handle()
    return Optional.of_nilable(self.handle)
end

function Package:get_install_path()
    return InstallLocation.global():package(self.name)
end

---@return Optional # Optional<InstallReceipt>
function Package:get_receipt()
    local receipt_path = path.concat { self:get_install_path(), "mason-receipt.json" }
    if fs.sync.file_exists(receipt_path) then
        local receipt = require "mason-core.receipt"
        return Optional.of(receipt.InstallReceipt.from_json(vim.json.decode(fs.sync.read_file(receipt_path))))
    end
    return Optional.empty()
end

---@return string?
function Package:get_installed_version()
    return self:get_receipt()
        :and_then(
            ---@param receipt InstallReceipt
            function(receipt)
                local source = receipt:get_source()
                if source.id then
                    return Purl.parse(source.id):map(_.prop "version"):ok()
                else
                    return Optional.empty()
                end
            end
        )
        :or_else(nil)
end

---@return string
function Package:get_latest_version()
    return Purl.parse(self.spec.source.id)
        :map(_.prop "version")
        :get_or_throw(("Unable to retrieve version from malformed purl: %s."):format(self.spec.source.id))
end

---@param opts? PackageInstallOpts
function Package:is_installable(opts)
    return require("mason-core.installer.compiler").parse(self.spec, opts or {}):is_success()
end

---@return Result # Result<string[]>
function Package:get_all_versions()
    local compiler = require "mason-core.installer.compiler"
    return Result.try(function(try)
        ---@type Purl
        local purl = try(Purl.parse(self.spec.source.id))
        ---@type InstallerCompiler
        local compiler = try(compiler.get_compiler(purl))
        return compiler.get_versions(purl, self.spec.source)
    end)
end

function Package:get_lsp_settings_schema()
    local schema_file = InstallLocation.global()
        :share(path.concat { "mason-schemas", "lsp", ("%s.json"):format(self.name) })
    if fs.sync.file_exists(schema_file) then
        return Result.pcall(vim.json.decode, fs.sync.read_file(schema_file), {
            luanil = { object = true, array = true },
        }):ok()
    end
    return Optional.empty()
end

function PackageMt.__tostring(self)
    return ("Package(name=%s)"):format(self.name)
end

function Package:get_aliases()
    return require("mason-registry").get_package_aliases(self.name)
end

return Package
