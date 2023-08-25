local Optional = require "mason-core.optional"
local Purl = require "mason-core.purl"
local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local link = require "mason-core.installer.registry.link"
local log = require "mason-core.log"
local schemas = require "mason-core.installer.registry.schemas"
local util = require "mason-core.installer.registry.util"

local M = {}

M.SCHEMA_CAP = _.set_of {
    "registry+v1",
}

---@type table<string, InstallerProvider>
local PROVIDERS = {}

---@param id string
---@param provider InstallerProvider
function M.register_provider(id, provider)
    PROVIDERS[id] = provider
end

M.register_provider("cargo", _.lazy_require "mason-core.installer.registry.providers.cargo")
M.register_provider("composer", _.lazy_require "mason-core.installer.registry.providers.composer")
M.register_provider("gem", _.lazy_require "mason-core.installer.registry.providers.gem")
M.register_provider("generic", _.lazy_require "mason-core.installer.registry.providers.generic")
M.register_provider("github", _.lazy_require "mason-core.installer.registry.providers.github")
M.register_provider("golang", _.lazy_require "mason-core.installer.registry.providers.golang")
M.register_provider("luarocks", _.lazy_require "mason-core.installer.registry.providers.luarocks")
M.register_provider("npm", _.lazy_require "mason-core.installer.registry.providers.npm")
M.register_provider("nuget", _.lazy_require "mason-core.installer.registry.providers.nuget")
M.register_provider("opam", _.lazy_require "mason-core.installer.registry.providers.opam")
M.register_provider("pypi", _.lazy_require "mason-core.installer.registry.providers.pypi")

---@param purl Purl
local function get_provider(purl)
    return Optional.of_nilable(PROVIDERS[purl.type]):ok_or(("Unknown purl type: %s"):format(purl.type))
end

---@class InstallerProvider
---@field parse fun(source: RegistryPackageSource, purl: Purl, opts: PackageInstallOpts): Result
---@field install async fun(ctx: InstallContext, source: ParsedPackageSource, purl: Purl): Result
---@field get_versions async fun(purl: Purl, source: RegistryPackageSource): Result # Result<string[]>

---@class ParsedPackageSource

---Upserts {dst} with contents of {src}. List table values will be merged, with contents of {src} prepended.
---@param dst table
---@param src table
local function upsert(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if vim.tbl_islist(v) then
                dst[k] = _.concat(v, dst[k] or {})
            else
                dst[k] = upsert(dst[k] or {}, src[k])
            end
        else
            dst[k] = v
        end
    end
    return dst
end

---@param source RegistryPackageSource
---@param version string
local function coalesce_source(source, version)
    if source.version_overrides then
        for i = #source.version_overrides, 1, -1 do
            local version_override = source.version_overrides[i]
            local version_type, constraint = unpack(_.split(":", version_override.constraint))
            if version_type == "semver" then
                local semver = require "mason-core.semver"
                local version_match = Result.try(function(try)
                    local requested_version = try(semver.parse(version))
                    if _.starts_with("<=", constraint) then
                        local rule_version = try(semver.parse(_.strip_prefix("<=", constraint)))
                        return requested_version <= rule_version
                    elseif _.starts_with(">=", constraint) then
                        local rule_version = try(semver.parse(_.strip_prefix(">=", constraint)))
                        return requested_version >= rule_version
                    else
                        local rule_version = try(semver.parse(constraint))
                        return requested_version == rule_version
                    end
                end):get_or_else(false)

                if version_match then
                    if version_override.id then
                        -- Because this entry provides its own purl id, it overrides the entire source definition.
                        return version_override
                    else
                        -- Upsert the default source with the contents of the version override.
                        return upsert(vim.deepcopy(source), _.dissoc("constraint", version_override))
                    end
                end
            end
        end
    end
    return source
end

---@param spec RegistryPackageSpec
---@param opts PackageInstallOpts
function M.parse(spec, opts)
    log.trace("Parsing spec", spec.name, opts)
    return Result.try(function(try)
        if not M.SCHEMA_CAP[spec.schema] then
            return Result.failure(
                ("Current version of mason.nvim is not capable of parsing package schema version %q."):format(
                    spec.schema
                )
            )
        end

        local source = opts.version and coalesce_source(spec.source, opts.version) or spec.source

        ---@type Purl
        local purl = try(Purl.parse(source.id))
        log.trace("Parsed purl.", source.id, purl)
        if opts.version then
            purl.version = opts.version
        end

        ---@type InstallerProvider
        local provider = try(get_provider(purl))
        log.trace("Found provider for purl.", source.id)
        local parsed_source = try(provider.parse(source, purl, opts))
        log.trace("Parsed source for purl.", source.id, parsed_source)
        return {
            provider = provider,
            source = vim.tbl_extend("keep", parsed_source, source),
            raw_source = source,
            purl = purl,
        }
    end):on_failure(function(err)
        log.debug("Failed to parse spec spec", spec.name, err)
    end)
end

---@async
---@param spec RegistryPackageSpec
---@param opts PackageInstallOpts
function M.compile(spec, opts)
    log.debug("Compiling installer.", spec.name, opts)
    return Result.try(function(try)
        -- Parsers run synchronously and may access API functions, so we schedule before-hand.
        a.scheduler()

        local map_parse_err = _.cond {
            {
                _.equals "PLATFORM_UNSUPPORTED",
                function()
                    if opts.target then
                        return ("Platform %q is unsupported."):format(opts.target)
                    else
                        return "The current platform is unsupported."
                    end
                end,
            },
            { _.T, _.identity },
        }

        ---@type { purl: Purl, provider: InstallerProvider, source: ParsedPackageSource, raw_source: RegistryPackageSource }
        local parsed = try(M.parse(spec, opts):map_err(map_parse_err))

        ---@async
        ---@param ctx InstallContext
        return function(ctx)
            return Result.try(function(try)
                if ctx.opts.version then
                    try(util.ensure_valid_version(function()
                        return parsed.provider.get_versions(parsed.purl, parsed.raw_source)
                    end))
                end

                -- Run installer
                try(parsed.provider.install(ctx, parsed.source, parsed.purl))

                if spec.schemas then
                    local result = schemas.download(ctx, spec, parsed.purl, parsed.source):on_failure(function(err)
                        log.error("Failed to download schemas", ctx.package, err)
                    end)
                    if opts.strict then
                        -- schema download sources are not considered stable nor a critical feature, so we only fail in strict mode
                        try(result)
                    end
                end

                -- Expand & register links
                if spec.bin then
                    try(link.bin(ctx, spec, parsed.purl, parsed.source))
                end
                if spec.share then
                    try(link.share(ctx, spec, parsed.purl, parsed.source))
                end
                if spec.opt then
                    try(link.opt(ctx, spec, parsed.purl, parsed.source))
                end

                ctx.receipt:with_primary_source {
                    type = ctx.package.spec.schema,
                    id = Purl.compile(parsed.purl),
                }
            end):on_failure(function(err)
                error(err, 0)
            end)
        end
    end)
end

---@async
---@param spec RegistryPackageSpec
function M.get_versions(spec)
    return Result.try(function(try)
        ---@type Purl
        local purl = try(Purl.parse(spec.source.id))
        ---@type InstallerProvider
        local provider = try(get_provider(purl))
        return provider.get_versions(purl, spec.source)
    end)
end

return M
