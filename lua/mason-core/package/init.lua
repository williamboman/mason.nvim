local EventEmitter = require "mason-core.EventEmitter"
local Optional = require "mason-core.optional"
local Purl = require "mason-core.purl"
local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local fs = require "mason-core.fs"
local log = require "mason-core.log"
local path = require "mason-core.path"
local registry = require "mason-registry"

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

---@class RegistryPackageSpec
---@field schema '"registry+v1"'
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

---@param opts? PackageInstallOpts
---@return InstallHandle
function Package:install(opts)
    opts = opts or {}
    return self:get_handle()
        :map(function(handle)
            if not handle:is_closed() then
                log.fmt_debug("Handle %s already exist for package %s", handle, self)
                return handle
            end
        end)
        :or_else_get(function()
            local handle = self:new_handle()
            a.run(
                require("mason-core.installer").execute,
                ---@param success boolean
                ---@param result Result
                function(success, result)
                    if not success then
                        -- Installer failed abnormally (i.e. unexpected exception in the installer code itself).
                        log.error("Unexpected error", result)
                        handle.stdio.sink.stderr(tostring(result))
                        handle.stdio.sink.stderr "\nInstallation failed abnormally. Please report this error."
                        self:emit("install:failed", handle)
                        registry:emit("package:install:failed", self, handle)

                        -- We terminate _after_ emitting failure events because [termination -> failed] have different
                        -- meaning than [failed -> terminate] ([termination -> failed] is interpreted as a triggered
                        -- termination).
                        if not handle:is_closed() and not handle.is_terminated then
                            handle:terminate()
                        end
                        return
                    end
                    result
                        :on_success(function()
                            self:emit("install:success", handle)
                            registry:emit("package:install:success", self, handle)
                        end)
                        :on_failure(function()
                            self:emit("install:failed", handle)
                            registry:emit("package:install:failed", self, handle)
                        end)
                end,
                handle,
                opts
            )
            return handle
        end)
end

function Package:uninstall()
    local was_unlinked = self:unlink()
    if was_unlinked then
        self:emit "uninstall:success"
        registry:emit("package:uninstall:success", self)
    end
    return was_unlinked
end

function Package:unlink()
    log.fmt_trace("Unlinking %s", self)
    local install_path = self:get_install_path()
    -- 1. Unlink
    self:get_receipt():if_present(function(receipt)
        local linker = require "mason-core.installer.linker"
        linker.unlink(self, receipt):get_or_throw()
    end)

    -- 2. Remove installation artifacts
    if fs.sync.dir_exists(install_path) then
        fs.sync.rmrf(install_path)
        return true
    end
    return false
end

function Package:is_installed()
    return registry.is_installed(self.name)
end

function Package:get_handle()
    return Optional.of_nilable(self.handle)
end

function Package:get_install_path()
    return path.package_prefix(self.name)
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
                return Purl.parse(receipt.primary_source.id):map(_.prop "version"):ok()
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
    return require("mason-core.installer.registry").parse(self.spec, opts or {}):is_success()
end

---@return Result # Result<string[]>
function Package:get_all_versions()
    local registry_installer = require "mason-core.installer.registry"
    return Result.try(function(try)
        ---@type Purl
        local purl = try(Purl.parse(self.spec.source.id))
        ---@type InstallerProvider
        local provider = try(registry_installer.get_provider(purl))
        return provider.get_versions(purl, self.spec.source)
    end)
end

function Package:get_lsp_settings_schema()
    local schema_file = path.share_prefix(path.concat { "mason-schemas", "lsp", ("%s.json"):format(self.name) })
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
