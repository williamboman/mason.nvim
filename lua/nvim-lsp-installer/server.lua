local dispatcher = require "nvim-lsp-installer.dispatcher"
local fs = require "nvim-lsp-installer.fs"
local log = require "nvim-lsp-installer.log"
local platform = require "nvim-lsp-installer.platform"
local settings = require "nvim-lsp-installer.settings"
local installers = require "nvim-lsp-installer.installers"
local servers = require "nvim-lsp-installer.servers"
local status_win = require "nvim-lsp-installer.ui.status-win"
local path = require "nvim-lsp-installer.path"

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
        languages = opts.languages or {},
        _on_ready_handlers = {},
        _installer = type(opts.installer) == "function" and opts.installer or installers.pipe(opts.installer),
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
    self:setup_lsp(opts)
    if not (opts.autostart == false) then
        self:attach_buffers()
    end
end

---Attaches this server to all current open buffers with a 'filetype' that matches the server's configured filetypes.
function M.Server:attach_buffers()
    log.debug("Attaching server to buffers", self.name)
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
    log.debug("Successfully attached server to buffers", self.name)
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

---@param context ServerInstallContext
---@param callback ServerInstallCallback
function M.Server:install_attached(context, callback)
    local context_ok, context_err = pcall(self._setup_install_context, self, context)
    if not context_ok then
        log.error("Failed to setup installation context.", context_err)
        callback(false)
        return
    end
    local install_ok, install_err = pcall(
        self._installer,
        self,
        vim.schedule_wrap(function(success)
            if success then
                if not self:promote_install_dir(context.install_dir) then
                    context.stdio_sink.stderr(
                        ("Failed to promote the temporary installation directory %q.\n"):format(context.install_dir)
                    )
                    pcall(fs.rmrf, self:get_tmp_install_dir())
                    pcall(fs.rmrf, context.install_dir)
                    callback(false)
                    return
                end

                -- The tmp dir should in most cases have been "promoted" and already renamed to its final destination,
                -- but we make sure to delete it should the installer modify the installation working directory during
                -- installation.
                pcall(fs.rmrf, self:get_tmp_install_dir())

                -- Dispatch the server is ready
                vim.schedule(function()
                    dispatcher.dispatch_server_ready(self)
                    for _, on_ready_handler in ipairs(self._on_ready_handlers) do
                        on_ready_handler(self)
                    end
                end)
                callback(true)
            else
                pcall(fs.rmrf, self:get_tmp_install_dir())
                pcall(fs.rmrf, context.install_dir)
                callback(false)
            end
        end),
        context
    )
    if not install_ok then
        log.error("Installer raised an unexpected error.", install_err)
        context.stdio_sink.stderr(tostring(install_err) .. "\n")
        callback(false)
    end
end

function M.Server:uninstall()
    log.debug("Uninstalling server", self.name)
    if fs.dir_exists(self.root_dir) then
        fs.rmrf(self.root_dir)
    end
end

return M
