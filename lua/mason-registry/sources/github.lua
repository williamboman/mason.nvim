local Optional = require "mason-core.optional"
local Pkg = require "mason-core.package"
local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local fetch = require "mason-core.fetch"
local fs = require "mason-core.fs"
local log = require "mason-core.log"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local providers = require "mason-core.providers"
local registry_installer = require "mason-core.installer.registry"
local settings = require "mason.settings"
local spawn = require "mason-core.spawn"

-- Parse sha256sum text output to a table<filename: string, sha256sum: string> structure
local parse_checksums = _.compose(_.from_pairs, _.map(_.compose(_.reverse, _.split "  ")), _.split "\n", _.trim)

---@class GitHubRegistrySourceSpec
---@field id string
---@field repo string
---@field namespace string
---@field name string
---@field version string?

---@class GitHubRegistrySource : RegistrySource
---@field spec GitHubRegistrySourceSpec
---@field repo string
---@field root_dir string
---@field private data_file string
---@field private info_file string
---@field buffer table<string, Package>?
local GitHubRegistrySource = {}
GitHubRegistrySource.__index = GitHubRegistrySource

---@param spec GitHubRegistrySourceSpec
function GitHubRegistrySource.new(spec)
    local root_dir = path.concat { path.registry_prefix(), "github", spec.namespace, spec.name }
    return setmetatable({
        id = spec.id,
        spec = spec,
        root_dir = root_dir,
        data_file = path.concat { root_dir, "registry.json" },
        info_file = path.concat { root_dir, "info.json" },
    }, GitHubRegistrySource)
end

function GitHubRegistrySource:is_installed()
    return fs.sync.file_exists(self.data_file)
end

function GitHubRegistrySource:reload()
    if not self:is_installed() then
        return
    end
    local data = vim.json.decode(fs.sync.read_file(self.data_file))
    self.buffer = _.compose(
        _.index_by(_.prop "name"),
        _.filter_map(
            ---@param spec RegistryPackageSpec
            function(spec)
                -- registry+v1 specifications doesn't include a schema property, so infer it
                spec.schema = spec.schema or "registry+v1"

                if not registry_installer.SCHEMA_CAP[spec.schema] then
                    log.fmt_debug("Excluding package=%s with unsupported schema_version=%s", spec.name, spec.schema)
                    return Optional.empty()
                end

                -- hydrate Pkg.Lang index
                _.each(function(lang)
                    local _ = Pkg.Lang[lang]
                end, spec.languages)

                -- XXX: this is for compatibilty with the PackageSpec structure
                spec.desc = spec.description

                local pkg = self.buffer and self.buffer[spec.name]
                if pkg then
                    -- Apply spec to the existing Package instance. This is important as to not have lingering package
                    -- instances.
                    pkg.spec = spec
                    return Optional.of(pkg)
                end
                return Optional.of(Pkg.new(spec))
            end
        )
    )(data)
    return self.buffer
end

function GitHubRegistrySource:get_buffer()
    return self.buffer or self:reload() or {}
end

---@param pkg string
---@return Package?
function GitHubRegistrySource:get_package(pkg)
    return self:get_buffer()[pkg]
end

function GitHubRegistrySource:get_all_package_names()
    return _.keys(self:get_buffer())
end

function GitHubRegistrySource:get_installer()
    return Optional.of(_.partial(self.install, self))
end

---@async
function GitHubRegistrySource:install()
    return Result.try(function(try)
        local version = self.spec.version
        if self:is_installed() and version ~= nil then
            -- Fixed version - nothing to update
            return
        end

        if not fs.async.dir_exists(self.root_dir) then
            log.debug("Creating registry directory", self)
            try(Result.pcall(fs.async.mkdirp, self.root_dir))
        end

        if version == nil then
            log.trace("Resolving latest version for registry", self)
            ---@type GitHubRelease
            local release = try(providers.github.get_latest_release(self.spec.repo))
            version = release.tag_name
            log.trace("Resolved latest registry version", self, version)
        end

        try(fetch(settings.current.github.download_url_template:format(self.spec.repo, version, "registry.json.zip"), {
            out_file = path.concat { self.root_dir, "registry.json.zip" },
        }):map_err(_.always "Failed to download registry.json.zip."))

        platform.when {
            unix = function()
                try(spawn.unzip({ "-o", "registry.json.zip", cwd = self.root_dir }):map_err(function(err)
                    return ("Failed to unpack registry contents: %s"):format(err.stderr)
                end))
            end,
            win = function()
                local powershell = require "mason-core.managers.powershell"
                powershell
                    .command(
                        ("Microsoft.PowerShell.Archive\\Expand-Archive -Force -Path %q -DestinationPath ."):format "registry.json.zip",
                        {
                            cwd = self.root_dir,
                        }
                    )
                    :map_err(function(err)
                        return ("Failed to unpack registry contents: %s"):format(err.stderr)
                    end)
            end,
        }
        pcall(fs.async.unlink, path.concat { self.root_dir, "registry.json.zip" })

        local checksums = try(
            fetch(settings.current.github.download_url_template:format(self.spec.repo, version, "checksums.txt")):map_err(
                _.always "Failed to download checksums.txt."
            )
        )

        try(Result.pcall(
            fs.async.write_file,
            self.info_file,
            vim.json.encode {
                checksums = parse_checksums(checksums),
                version = version,
                download_timestamp = os.time(),
            }
        ))
    end)
        :on_success(function()
            self:reload()
        end)
        :on_failure(function(err)
            log.fmt_error("Failed to install registry %s. %s", self, err)
        end)
end

---@return { checksums: table<string, string>, version: string, download_timestamp: integer }
function GitHubRegistrySource:get_info()
    return vim.json.decode(fs.sync.read_file(self.info_file))
end

function GitHubRegistrySource:get_display_name()
    if self:is_installed() then
        local info = self:get_info()
        return ("github.com/%s version: %s"):format(self.spec.repo, info.version)
    else
        return ("github.com/%s [uninstalled]"):format(self.spec.repo)
    end
end

function GitHubRegistrySource:__tostring()
    if self.spec.version then
        return ("GitHubRegistrySource(repo=%s, version=%s)"):format(self.spec.repo, self.spec.version)
    else
        return ("GitHubRegistrySource(repo=%s)"):format(self.spec.repo)
    end
end

return GitHubRegistrySource
