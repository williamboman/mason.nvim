local Optional = require "mason-core.optional"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local client = require "mason-core.managers.cargo.client"
local github = require "mason-core.managers.github"
local github_client = require "mason-core.managers.github.client"
local installer = require "mason-core.installer"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local spawn = require "mason-core.spawn"

local get_bin_path = _.compose(path.concat, function(executable)
    return _.append(executable, { "bin" })
end, _.if_else(_.always(platform.is.win), _.format "%s.exe", _.identity))

---@param crate string
local function with_receipt(crate)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.cargo(crate))
    end
end

local M = {}

---@async
---@param crate string The crate to install.
---@param opts { git: { url: string, tag: boolean? }, features: string?, bin: string[]? }?
function M.crate(crate, opts)
    return function()
        if opts and opts.git and opts.git.tag then
            local ctx = installer.context()
            local repo = assert(opts.git.url:match "^https://github%.com/(.+)$", "git url needs to be github.com")
            local source = github.tag { repo = repo }
            source.with_receipt()
            ctx.requested_version = Optional.of(source.tag)
            M.install(crate, opts)
        else
            M.install(crate, opts).with_receipt()
        end
    end
end

---@async
---@param crate string The crate to install.
---@param opts { git: { url: string, tag: boolean? }, features: string?, bin: string[]? }?
function M.install(crate, opts)
    local ctx = installer.context()
    opts = opts or {}

    local version

    if opts.git then
        if opts.git.tag then
            assert(ctx.requested_version:is_present(), "version is required when installing tagged git crate.")
        end
        version = ctx.requested_version
            :map(function(version)
                if opts.git.tag then
                    return { "--tag", version }
                else
                    return { "--rev", version }
                end
            end)
            :or_else(vim.NIL)
    else
        version = ctx.requested_version
            :map(function(version)
                return { "--version", version }
            end)
            :or_else(vim.NIL)
    end

    ctx.spawn.cargo {
        "install",
        "--root",
        ".",
        "--locked",
        version,
        opts.git and { "--git", opts.git.url } or vim.NIL,
        opts.features and { "--features", opts.features } or vim.NIL,
        crate,
    }

    if opts.bin then
        _.each(function(bin)
            ctx:link_bin(bin, get_bin_path(bin))
        end, opts.bin)
    end

    return {
        with_receipt = with_receipt(crate),
    }
end

---@alias InstalledCrate { name: string, version: string, github_ref: { owner: string, repo: string, ref: string }? }

---@param line string
---@return InstalledCrate? crate
local function parse_installed_crate(line)
    local name, version, context = line:match "^(.+)%s+v([^%s:]+) ?(.*):$"
    if context then
        local owner, repo, ref = context:match "^%(https://github%.com/(.+)/([^?]+).*#(.+)%)$"
        if ref then
            return { name = name, version = ref, github_ref = { owner = owner, repo = repo, ref = ref } }
        end
    end
    if name and version then
        return { name = name, version = version }
    end
end

---@param output string The `cargo install --list` output.
---@return table<string, InstalledCrate> # Key is the crate name, value is its version.
function M.parse_installed_crates(output)
    local installed_crates = {}
    for _, line in ipairs(vim.split(output, "\n")) do
        local installed_crate = parse_installed_crate(line)
        if installed_crate then
            installed_crates[installed_crate.name] = installed_crate
        end
    end
    return installed_crates
end

---@async
---@param install_dir string
---@return Result # Result<table<string, InstalledCrate>>
local function get_installed_crates(install_dir)
    return spawn
        .cargo({
            "install",
            "--list",
            "--root",
            ".",
            cwd = install_dir,
        })
        :map_catching(function(result)
            return M.parse_installed_crates(result.stdout)
        end)
end

---@async
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    a.scheduler()
    local crate_name = vim.fn.fnamemodify(receipt.primary_source.package, ":t")
    return get_installed_crates(install_dir)
        :ok()
        :map(_.prop(crate_name))
        :map(
            ---@param installed_crate InstalledCrate
            function(installed_crate)
                if installed_crate.github_ref then
                    ---@type GitHubCommit
                    local latest_commit = github_client
                        .fetch_commits(
                            ("%s/%s"):format(installed_crate.github_ref.owner, installed_crate.github_ref.repo),
                            { page = 1, per_page = 1 }
                        )
                        :get_or_throw("Failed to fetch latest commits.")[1]
                    if not vim.startswith(latest_commit.sha, installed_crate.github_ref.ref) then
                        return {
                            name = receipt.primary_source.package,
                            current_version = installed_crate.github_ref.ref,
                            latest_version = latest_commit.sha,
                        }
                    end
                else
                    ---@type CrateResponse
                    local crate_response = client.fetch_crate(crate_name):get_or_throw()
                    if installed_crate.version ~= crate_response.crate.max_stable_version then
                        return {
                            name = receipt.primary_source.package,
                            current_version = installed_crate.version,
                            latest_version = crate_response.crate.max_stable_version,
                        }
                    end
                end
            end
        )
        :ok_or(_.always "Primary package is not outdated.")
end

---@async
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    a.scheduler()
    local crate_name = vim.fn.fnamemodify(receipt.primary_source.package, ":t")
    return get_installed_crates(install_dir)
        :ok()
        :map(_.prop(crate_name))
        :map(_.prop "version")
        :ok_or(_.always "Failed to find cargo package version.")
end

return M
