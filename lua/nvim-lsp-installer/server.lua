local dispatcher = require "nvim-lsp-installer.dispatcher"
local a = require "nvim-lsp-installer.core.async"
local InstallContext = require "nvim-lsp-installer.core.installer.context"
local fs = require "nvim-lsp-installer.fs"
local log = require "nvim-lsp-installer.log"
local platform = require "nvim-lsp-installer.platform"
local settings = require "nvim-lsp-installer.settings"
local installers = require "nvim-lsp-installer.installers"
local installer = require "nvim-lsp-installer.core.installer"
local servers = require "nvim-lsp-installer.servers"
local status_win = require "nvim-lsp-installer.ui.status-win"
local path = require "nvim-lsp-installer.path"
local receipt = require "nvim-lsp-installer.core.receipt"
local Optional = require "nvim-lsp-installer.core.optional"

local M = {}

-- old, but also somewhat convenient, API
M.get_server_root_path = servers.get_server_install_path

---@alias ServerDeprecation {message:string, replace_with:string|nil}
---@alias ServerOpts {name:string, root_dir:string, homepage:string|nil, deprecated:ServerDeprecation, installer:ServerInstallerFunction|ServerInstallerFunction[], default_options:table, languages: string[]}

---@class Server
---@field public  name string @The server name. This is the same as lspconfig's server names.
---@field public  root_dir string @The directory where the server should be installed in.
---@field public  homepage string|nil @The homepage where users can find more information. This is shown to users in the UI.
---@field public  deprecated ServerDeprecation|nil @The existence (not nil) of this field indicates this server is depracted.
---@field public  languages string[]
---@field private _installer ServerInstallerFunction
---@field private _async boolean
---@field private _on_ready_handlers fun(server: Server)[]
---@field private _default_options table @The server's default options. This is used in @see Server#setup.
M.Server = {}
M.Server.__index = M.Server

---@param opts ServerOpts
---@return Server
function M.Server:new(opts)
    return setmetatable({
        name = opts.name,
        root_dir = opts.root_dir,
        homepage = opts.homepage,
        deprecated = opts.deprecated,
        _async = opts.async or false,
        languages = opts.languages or {},
        _on_ready_handlers = {},
        _installer = opts.installer,
        _default_options = opts.default_options,
    }, M.Server)
end

---Sets up the language server via lspconfig. This function has the same signature as the setup function in nvim-lspconfig.
---@param opts table @The lspconfig server configuration.
function M.Server:setup_lsp(opts)
    -- We require the lspconfig server here in order to do it as late as possible.
    -- The reason for this is because once a lspconfig server has been imported, it's
    -- automatically registered with lspconfig and causes it to show up in :LspInfo and whatnot.
    local lsp_server = require("lspconfig")[self.name]
    if lsp_server then
        lsp_server.setup(vim.tbl_deep_extend("force", self._default_options, opts or {}))
    else
        error(
            (
                "Unable to setup server %q: Could not find lspconfig server entry. Make sure you are running a recent version of lspconfig."
            ):format(self.name)
        )
    end
end

---Sets up the language server and attaches all open buffers.
---@param opts table @The lspconfig server configuration.
function M.Server:setup(opts)
    assert(
        not settings.uses_new_setup,
        "Please set up servers directly via lspconfig instead of going through nvim-lsp-installer (this method is now deprecated)! Refer to :h nvim-lsp-installer-quickstart for more information."
    )
    self:setup_lsp(opts)
    if not (opts.autostart == false) then
        self:attach_buffers()
    end
end

---Attaches this server to all current open buffers with a 'filetype' that matches the server's configured filetypes.
function M.Server:attach_buffers()
    log.trace("Attaching server to buffers", self.name)
    local lsp_server = require("lspconfig")[self.name]
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if lsp_server.filetypes then
            log.fmt_trace("Attaching server=%s to bufnr=%s using filetypes wrapper", self.name, bufnr)
            lsp_server.manager.try_add_wrapper(bufnr)
        else
            log.fmt_trace("Attaching server=%s to bufnr=%s", self.name, bufnr)
            lsp_server.manager.try_add(bufnr)
        end
    end
    log.trace("Successfully attached server to buffers", self.name)
end

---Registers a handler (callback) to be executed when the server is ready to be setup.
---@param handler fun(server: Server)
function M.Server:on_ready(handler)
    table.insert(self._on_ready_handlers, handler)
    if self:is_installed() then
        handler(self)
    end
end

---@return table @A deep copy of this server's default options. Note that these default options are nvim-lsp-installer specific, and does not include any default options provided by lspconfig.
function M.Server:get_default_options()
    return vim.deepcopy(self._default_options)
end

---@return string[] @The list of supported filetypes.
function M.Server:get_supported_filetypes()
    local metadata = require "nvim-lsp-installer._generated.metadata"

    if metadata[self.name] then
        return metadata[self.name].filetypes
    end

    return {}
end

function M.Server:get_settings_schema()
    local ok, schema = pcall(require, ("nvim-lsp-installer._generated.schemas.%s"):format(self.name))
    return (ok and schema) or nil
end

---@return boolean
function M.Server:is_installed()
    return servers.is_server_installed(self.name)
end

---Queues the server to be asynchronously installed.
---@param version string|nil @The version of the server to install. If nil, the latest version will be installed.
function M.Server:install(version)
    status_win().install_server(self, version)
end

function M.Server:get_tmp_install_dir()
    return path.concat { settings.current.install_root_dir, ("%s.tmp"):format(self.name) }
end

---@param context ServerInstallContext
function M.Server:_setup_install_context(context)
    context.install_dir = self:get_tmp_install_dir()
    fs.rm_mkdirp(context.install_dir)

    if not fs.dir_exists(settings.current.install_root_dir) then
        fs.mkdirp(settings.current.install_root_dir)
    end
end

---Removes any existing installation of the server, and moves/promotes the provided install_dir directory to its place.
---@param install_dir string @The installation directory to move to the server's root directory.
function M.Server:promote_install_dir(install_dir)
    if self.root_dir == install_dir then
        log.fmt_debug("Install dir %s is already promoted for %s", install_dir, self.name)
        return true
    end
    log.fmt_debug("Promoting installation directory %s for %s", install_dir, self.name)
    -- 1. Remove final installation directory, if it exists
    if fs.dir_exists(self.root_dir) then
        local rmrf_ok, rmrf_err = pcall(fs.rmrf, self.root_dir)
        if not rmrf_ok then
            log.fmt_error("Failed to remove final installation directory. path=%s error=%s", self.root_dir, rmrf_err)
            return false
        end
    end

    -- 2. Move the temporary install dir to the final installation directory
    if platform.is_unix then
        -- Some Unix systems will raise an error when renaming a directory to a destination that does not already exist.
        fs.mkdir(self.root_dir)
    end
    local rename_ok, rename_err = pcall(fs.rename, install_dir, self.root_dir)
    if not rename_ok then
        --- 2a. We failed to rename the temporary dir to the final installation dir
        log.fmt_error("Failed to rename. path=%s new_path=%s error=%s", install_dir, self.root_dir, rename_err)
        return false
    end
    log.fmt_debug("Successfully promoted install_dir=%s for %s", install_dir, self.name)
    return true
end

function M.Server:_get_receipt_path()
    return path.concat { self.root_dir, "nvim-lsp-installer-receipt.json" }
end

---@param receipt_builder InstallReceiptBuilder
function M.Server:_write_receipt(receipt_builder)
    if receipt_builder.is_marked_invalid then
        log.fmt_debug("Skipping writing receipt for %s because it is marked as invalid.", self.name)
        return
    end
    receipt_builder:with_name(self.name):with_schema_version("1.0a"):with_completion_time(vim.loop.gettimeofday())

    local receipt_success, install_receipt = pcall(receipt_builder.build, receipt_builder)
    if receipt_success then
        pcall(fs.write_file, self:_get_receipt_path(), vim.json.encode(install_receipt))
    else
        log.fmt_error("Failed to build receipt for server=%s. Error=%s", self.name, install_receipt)
    end
end

---@return InstallReceipt|nil
function M.Server:get_receipt()
    local receipt_path = self:_get_receipt_path()
    if fs.file_exists(receipt_path) then
        local receipt_json = vim.json.decode(fs.read_file(receipt_path))
        return receipt.InstallReceipt.from_json(receipt_json)
    end
    return nil
end

---@param context ServerInstallContext
---@param callback ServerInstallCallback
function M.Server:install_attached(context, callback)
    if self._async then
        a.run(function()
            local install_context = InstallContext.new {
                name = self.name,
                boundary_path = settings.current.install_root_dir,
                stdio_sink = context.stdio_sink,
                destination_dir = self.root_dir,
                requested_version = Optional.of_nilable(context.requested_server_version),
            }
            installer.execute(install_context, self._installer):get_or_throw()
            a.scheduler()
            dispatcher.dispatch_server_ready(self)
            for _, on_ready_handler in ipairs(self._on_ready_handlers) do
                on_ready_handler(self)
            end
        end, callback)
    else
        --- Deprecated
        a.run(
            function()
                context.receipt = receipt.InstallReceiptBuilder.new()
                context.receipt:with_start_time(vim.loop.gettimeofday())

                a.scheduler()
                self:_setup_install_context(context)
                local async_installer = a.promisify(function(server, context, callback)
                    local normalized_installer = type(self._installer) == "function" and self._installer
                        or installers.pipe(self._installer)
                    -- args are shifted
                    return normalized_installer(server, callback, context)
                end)
                assert(async_installer(self, context), "Installation failed.")

                a.scheduler()
                if not self:promote_install_dir(context.install_dir) then
                    error(("Failed to promote the temporary installation directory %q."):format(context.install_dir))
                end

                self:_write_receipt(context.receipt)

                -- Dispatch the server is ready
                vim.schedule(function()
                    dispatcher.dispatch_server_ready(self)
                    for _, on_ready_handler in ipairs(self._on_ready_handlers) do
                        on_ready_handler(self)
                    end
                end)
            end,
            vim.schedule_wrap(function(ok, result)
                if not ok then
                    pcall(fs.rmrf, context.install_dir)
                    log.fmt_error("Server installation failed, server_name=%s, error=%s", self.name, result)
                    context.stdio_sink.stderr(tostring(result) .. "\n")
                end
                -- The tmp dir should in most cases have been "promoted" and already renamed to its final destination,
                -- but we make sure to delete it should the installer modify the installation working directory during
                -- installation.
                pcall(fs.rmrf, self:get_tmp_install_dir())
                callback(ok)
            end)
        )
    end
end

function M.Server:uninstall()
    log.debug("Uninstalling server", self.name)
    if fs.dir_exists(self.root_dir) then
        fs.rmrf(self.root_dir)
    end
end

return M
