local dispatcher = require "nvim-lsp-installer.dispatcher"
local fs = require "nvim-lsp-installer.fs"
local log = require "nvim-lsp-installer.log"
local settings = require "nvim-lsp-installer.settings"
local installers = require "nvim-lsp-installer.installers"
local servers = require "nvim-lsp-installer.servers"
local status_win = require "nvim-lsp-installer.ui.status-win"
local path = require "nvim-lsp-installer.path"

local M = {}

-- old, but also somewhat convenient, API
M.get_server_root_path = servers.get_server_install_path

---@alias ServerDeprecation {message:string, replace_with:string|nil}
---@alias ServerOpts {name:string, root_dir:string, homepage:string|nil, deprecated:ServerDeprecation, installer:ServerInstallerFunction|ServerInstallerFunction[], default_options:table, pre_setup:fun()|nil, post_setup:fun()|nil}

---@class Server
---@field public  name string @The server name. This is the same as lspconfig's server names.
---@field public  root_dir string @The directory where the server should be installed in.
---@field public  homepage string|nil @The homepage where users can find more information. This is shown to users in the UI.
---@field public  deprecated ServerDeprecation|nil @The existence (not nil) of this field indicates this server is depracted.
---@field private _installer ServerInstallerFunction
---@field private _on_ready_handlers fun(server: Server)[]
---@field private _default_options table @The server's default options. This is used in @see Server#setup.
---@field private _pre_setup fun()|nil @Function to be called in @see Server#setup, before trying to setup.
---@field private _post_setup fun()|nil @Function to be called in @see Server#setup, after successful setup.
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
        _on_ready_handlers = {},
        _installer = type(opts.installer) == "function" and opts.installer or installers.pipe(opts.installer),
        _default_options = opts.default_options,
        _pre_setup = opts.pre_setup,
        _post_setup = opts.post_setup,
    }, M.Server)
end

---@param opts table @User-defined options. This is directly passed to the lspconfig's setup() method.
function M.Server:setup(opts)
    if self._pre_setup then
        log.fmt_debug("Calling pre_setup for server=%s", self.name)
        self._pre_setup()
    end
    -- We require the lspconfig server here in order to do it as late as possible.
    -- The reason for this is because once a lspconfig server has been imported, it's
    -- automatically registered with lspconfig and causes it to show up in :LspInfo and whatnot.
    local lsp_server = require("lspconfig")[self.name]
    if lsp_server then
        lsp_server.setup(vim.tbl_deep_extend("force", self._default_options, opts or {}))
        if self._post_setup then
            log.fmt_debug("Calling post_setup for server=%s", self.name)
            self._post_setup()
        end
    else
        error(
            (
                "Unable to setup server %q: Could not find lspconfig server entry. Make sure you are running a recent version of lspconfig."
            ):format(self.name)
        )
    end
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
function M.Server:install()
    status_win().install_server(self)
end

---@param context ServerInstallContext
function M.Server:_setup_install_context(context)
    context.install_dir = path.concat { settings.current.install_root_dir, ("%s.tmp"):format(self.name) }
    fs.rm_mkdirp(context.install_dir)

    if not fs.dir_exists(settings.current.install_root_dir) then
        fs.mkdirp(settings.current.install_root_dir)
    end
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
                -- 1. Remove and recreate final installation directory
                local rmrf_ok, rmrf_err = pcall(fs.rm_mkdirp, self.root_dir)
                if not rmrf_ok then
                    log.fmt_error("Failed to rm_mkdirp. path=%s error=%s", self.root_dir, rmrf_err)
                    context.stdio_sink.stderr "Failed to remove and recreate final installation directory.\n"
                    context.stdio_sink.stderr(tostring(rmrf_err) .. "\n")
                    callback(false)
                    return
                end

                -- 2. Move the temporary install dir to the final installation directory
                local rename_ok, rename_err = pcall(fs.rename, context.install_dir, self.root_dir)
                if rename_ok then
                    -- 3a. Dispatch the server is ready
                    vim.schedule(function()
                        dispatcher.dispatch_server_ready(self)
                        for _, on_ready_handler in ipairs(self._on_ready_handlers) do
                            on_ready_handler(self)
                        end
                    end)
                else
                    --- 3b. We failed to rename the temporary dir to the final installation dir
                    log.fmt_error(
                        "Failed to rename. path=%s new_path=%s error=%s",
                        context.install_dir,
                        self.root_dir,
                        rename_err
                    )
                    context.stdio_sink.stderr(
                        ("Failed to rename %q to %q.\n"):format(context.install_dir, self.root_dir)
                    )
                    context.stdio_sink.stderr(tostring(rename_err) .. "\n")
                    callback(false)
                    return
                end
            end
            callback(success)
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
