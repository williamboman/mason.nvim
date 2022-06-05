local dispatcher = require "nvim-lsp-installer.dispatcher"
local a = require "nvim-lsp-installer.core.async"
local InstallContext = require "nvim-lsp-installer.core.installer.context"
local fs = require "nvim-lsp-installer.core.fs"
local log = require "nvim-lsp-installer.log"
local settings = require "nvim-lsp-installer.settings"
local installer = require "nvim-lsp-installer.core.installer"
local servers = require "nvim-lsp-installer.servers"
local status_win = require "nvim-lsp-installer.ui"
local path = require "nvim-lsp-installer.core.path"
local receipt = require "nvim-lsp-installer.core.receipt"
local Optional = require "nvim-lsp-installer.core.optional"

local M = {}

-- old, but also somewhat convenient, API
M.get_server_root_path = servers.get_server_install_path

---@alias ServerDeprecation {message:string, replace_with:string|nil}
---@alias ServerOpts {name:string, root_dir:string, homepage:string|nil, deprecated:ServerDeprecation, installer:async fun(ctx: InstallContext), default_options:table, languages: string[]}

---@class Server
---@field public  name string @The server name. This is the same as lspconfig's server names.
---@field public  root_dir string @The directory where the server should be installed in.
---@field public  homepage string|nil @The homepage where users can find more information. This is shown to users in the UI.
---@field public  deprecated ServerDeprecation|nil @The existence (not nil) of this field indicates this server is depracted.
---@field public  languages string[]
---@field private _installer async fun(ctx: InstallContext)
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
        _installer = opts.installer,
        _default_options = opts.default_options,
    }, M.Server)
end

---Sets up the language server via lspconfig. This function has the same signature as the setup function in nvim-lspconfig.
---@param opts table @The lspconfig server configuration.
function M.Server:setup_lsp(opts)
    assert(
        not settings.uses_new_setup,
        "Please set up servers directly via lspconfig instead of going through nvim-lsp-installer (this method is now deprecated)! Refer to :h nvim-lsp-installer-quickstart for more information."
    )
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

function M.Server:_get_receipt_path()
    return path.concat { self.root_dir, "nvim-lsp-installer-receipt.json" }
end

---@return InstallReceipt|nil
function M.Server:get_receipt()
    local receipt_path = self:_get_receipt_path()
    if fs.sync.file_exists(receipt_path) then
        local receipt_json = vim.json.decode(fs.sync.read_file(receipt_path))
        return receipt.InstallReceipt.from_json(receipt_json)
    end
    return nil
end

---@param context table
---@param callback fun(success: boolean)
function M.Server:install_attached(context, callback)
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
end

function M.Server:uninstall()
    log.debug("Uninstalling server", self.name)
    if fs.sync.dir_exists(self.root_dir) then
        fs.sync.rmrf(self.root_dir)
    end
end

return M
