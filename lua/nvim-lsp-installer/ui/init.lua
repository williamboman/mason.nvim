local a = require "nvim-lsp-installer.core.async"
local Ui = require "nvim-lsp-installer.core.ui"
local display = require "nvim-lsp-installer.core.ui.display"
local fs = require "nvim-lsp-installer.core.fs"
local log = require "nvim-lsp-installer.log"
local _ = require "nvim-lsp-installer.core.functional"
local settings = require "nvim-lsp-installer.settings"
local lsp_servers = require "nvim-lsp-installer.servers"
local JobExecutionPool = require "nvim-lsp-installer.jobs.pool"
local outdated_servers = require "nvim-lsp-installer.jobs.outdated-servers"
local version_check = require "nvim-lsp-installer.jobs.version-check"
local ServerHints = require "nvim-lsp-installer.ui.server_hints"
local ServerSettingsSchema = require "nvim-lsp-installer.ui.components.settings-schema"

local HELP_KEYMAP = "?"
local CLOSE_WINDOW_KEYMAP_1 = "<Esc>"
local CLOSE_WINDOW_KEYMAP_2 = "q"

---@param props {title: string, diagnostics: table|nil, subtitle: string[][], count: number}
local function ServerGroupHeading(props)
    local line = {
        { props.title, props.highlight or "LspInstallerHeading" },
        { " (" .. props.count .. ") ", "Comment" },
    }
    if props.subtitle then
        vim.list_extend(line, props.subtitle)
    end
    return Ui.Node {
        Ui.HlTextNode { line },
        Ui.When(props.diagnostics, Ui.DiagnosticsNode(props.diagnostics)),
    }
end

local function Indent(children)
    return Ui.CascadingStyleNode({ "INDENT" }, children)
end

local create_vader = _.memoize(
    ---@param saber_ticks number
    function(saber_ticks)
    -- stylua: ignore start
    return {
        { { [[ _________________________________________________________________________________________ ]], "LspInstallerMuted" } },
        { { [[ < Help sponsor nvim-lsp-installer development! ]], "LspInstallerMuted" }, { "https://github.com/sponsors/williamboman", "LspInstallerHighlighted"}, {[[ > ]], "LspInstallerMuted" } },
        { { [[ < Help sponsor neovim development! ]], "LspInstallerMuted" }, { "https://github.com/sponsors/neovim", "LspInstallerHighlighted"}, {[[                   > ]], "LspInstallerMuted" } },
        { { [[ ----------------------------------------------------------------------------------------- ]], "LspInstallerMuted" } },
        { { [[        ]], ""}, {[[\]], saber_ticks >= 3 and "LspInstallerVaderSaber" or "LspInstallerMuted"}, {[[    ,-^-.                                                       ]], "LspInstallerMuted" } },
        { { [[         ]], ""}, {[[\]], saber_ticks >= 2 and "LspInstallerVaderSaber" or "LspInstallerMuted"}, {[[   !oYo!                                                       ]], "LspInstallerMuted" } },
        { { [[          ]], ""}, {[[\]], saber_ticks >= 1 and "LspInstallerVaderSaber" or "LspInstallerMuted"}, {[[ /./=\.\______                                                ]], "LspInstallerMuted" } },
        { { [[               ##        )\/\                                            ]], "LspInstallerMuted" } },
        { { [[                ||-----w||                                               ]], "LspInstallerMuted" } },
        { { [[                ||      ||                                               ]], "LspInstallerMuted" } },
        { { [[                                                                         ]], "LspInstallerMuted" } },
        { { [[         Cowth Vader (alleged Neovim user)                               ]], "LspInstallerMuted" } },
        { { [[                                                                         ]], "LspInstallerMuted" } },
    }
        -- stylua: ignore end
    end
)

---@param is_current_settings_expanded boolean
---@param vader_saber_ticks number
local function Help(is_current_settings_expanded, vader_saber_ticks)
    local keymap_tuples = {
        { "Toggle help", HELP_KEYMAP },
        { "Toggle server info", settings.current.ui.keymaps.toggle_server_expand },
        { "Update server", settings.current.ui.keymaps.update_server },
        { "Update all installed servers", settings.current.ui.keymaps.update_all_servers },
        { "Check for new server version", settings.current.ui.keymaps.check_server_version },
        { "Check for new versions (all servers)", settings.current.ui.keymaps.check_outdated_servers },
        { "Uninstall server", settings.current.ui.keymaps.uninstall_server },
        { "Install server", settings.current.ui.keymaps.install_server },
        { "Close window", CLOSE_WINDOW_KEYMAP_1 },
        { "Close window", CLOSE_WINDOW_KEYMAP_2 },
    }

    local very_reasonable_cow = create_vader(vader_saber_ticks)

    return Ui.Node {
        Ui.EmptyLine(),
        Ui.HlTextNode {
            { { "Installer log: ", "LspInstallerMuted" }, { log.outfile, "" } },
        },
        Ui.EmptyLine(),
        Ui.Table(vim.list_extend(
            {
                {
                    { "Keyboard shortcuts", "LspInstallerLabel" },
                },
            },
            _.map(function(keymap_tuple)
                return { { keymap_tuple[1], "LspInstallerMuted" }, { keymap_tuple[2], "LspInstallerHighlighted" } }
            end, keymap_tuples)
        )),
        Ui.EmptyLine(),
        Ui.HlTextNode {
            { { "Problems installing/uninstalling servers", "LspInstallerLabel" } },
            {
                {
                    "Make sure you meet the minimum requirements to install servers. For debugging, refer to:",
                    "LspInstallerMuted",
                },
            },
        },
        Indent {
            Ui.HlTextNode {
                {
                    { ":help nvim-lsp-installer-debugging", "LspInstallerHighlighted" },
                },
                {
                    { ":checkhealth nvim-lsp-installer", "LspInstallerHighlighted" },
                },
            },
        },
        Ui.EmptyLine(),
        Ui.HlTextNode {
            { { "Problems with server functionality", "LspInstallerLabel" } },
            {
                {
                    "Please refer to each language server's own homepage for further assistance.",
                    "LspInstallerMuted",
                },
            },
        },
        Ui.EmptyLine(),
        Ui.HlTextNode {
            { { "Missing a server?", "LspInstallerLabel" } },
            {
                {
                    "Create an issue at ",
                    "LspInstallerMuted",
                },
                {
                    "https://github.com/williamboman/nvim-lsp-installer/issues/new/choose",
                    "LspInstallerHighlighted",
                },
            },
        },
        Ui.EmptyLine(),
        Ui.HlTextNode {
            { { "How do I customize server settings?", "LspInstallerLabel" } },
            {
                { "For information on how to customize a server's settings, see ", "LspInstallerMuted" },
                { ":help lspconfig-setup", "LspInstallerHighlighted" },
            },
        },
        Ui.EmptyLine(),
        Ui.HlTextNode {
            {
                {
                    ("%s Current settings"):format(is_current_settings_expanded and "↓" or "→"),
                    "LspInstallerLabel",
                },
                { " :help nvim-lsp-installer-settings", "LspInstallerHighlighted" },
            },
        },
        Ui.Keybind("<CR>", "TOGGLE_EXPAND_CURRENT_SETTINGS", nil),
        Ui.When(is_current_settings_expanded, function()
            local settings_split_by_newline = vim.split(vim.inspect(settings.current), "\n")
            local current_settings = _.map(function(line)
                return { { line, "LspInstallerMuted" } }
            end, settings_split_by_newline)
            return Ui.HlTextNode(current_settings)
        end),
        Ui.EmptyLine(),
        Ui.HlTextNode(very_reasonable_cow),
    }
end

---@param props {is_showing_help: boolean, help_command_text: string}
local function Header(props)
    return Ui.CascadingStyleNode({ "CENTERED" }, {
        Ui.HlTextNode {
            {
                { props.is_showing_help and (" " .. props.help_command_text) or "", "LspInstallerHeaderHelp" },
                {
                    props.is_showing_help and "nvim-lsp-installer " or " nvim-lsp-installer ",
                    props.is_showing_help and "LspInstallerHeaderHelp" or "LspInstallerHeader",
                },
                {
                    props.is_showing_help and (" "):rep(#props.help_command_text) or "",
                    "",
                },
            },
            {
                { props.is_showing_help and "       press " or "press ", "LspInstallerMuted" },
                { "?", props.is_showing_help and "LspInstallerOrange" or "LspInstallerHighlighted" },
                { props.is_showing_help and " for server list" or " for help", "LspInstallerMuted" },
            },
            {
                { "https://github.com/williamboman/nvim-lsp-installer", "Comment" },
            },
        },
    })
end

---@param time number
local function format_time(time)
    return os.date("%d %b %Y %H:%M", time)
end

---@param outdated_packages OutdatedPackage[]
---@return string
local function format_new_package_versions(outdated_packages)
    local result = {}
    if #outdated_packages == 1 then
        return outdated_packages[1].latest_version
    end
    for _, outdated_package in ipairs(outdated_packages) do
        result[#result + 1] = ("%s@%s"):format(outdated_package.name, outdated_package.latest_version)
    end
    return table.concat(result, ", ")
end

---@param server ServerState
local function ServerMetadata(server)
    return Ui.Node(_.list_not_nil(
        _.lazy_when(server.is_installed and server.deprecated, function()
            return Ui.Node(_.list_not_nil(
                Ui.HlTextNode { server.deprecated.message, "Comment" },
                _.lazy_when(server.deprecated.replace_with, function()
                    return Ui.Node {
                        Ui.HlTextNode {
                            {
                                { "Replace with: ", "LspInstallerMuted" },
                                { server.deprecated.replace_with, "LspInstallerHighlighted" },
                            },
                        },
                        Ui.Keybind("<CR>", "REPLACE_SERVER", { server.name, server.deprecated.replace_with }),
                        Ui.EmptyLine(),
                    }
                end)
            ))
        end),
        Ui.Table(_.list_not_nil(
            _.lazy_when(server.is_installed, function()
                return {
                    { "version", "LspInstallerMuted" },
                    server.installed_version_err and {
                        "Unable to detect version.",
                        "LspInstallerMuted",
                    } or { server.installed_version or "Loading...", "" },
                }
            end),
            _.lazy_when(#server.metadata.outdated_packages > 0, function()
                return {
                    { "latest version", "LspInstallerGreen" },
                    {
                        format_new_package_versions(server.metadata.outdated_packages),
                        "LspInstallerGreen",
                    },
                }
            end),
            _.lazy_when(server.metadata.install_timestamp_seconds, function()
                return {
                    { "installed", "LspInstallerMuted" },
                    { format_time(server.metadata.install_timestamp_seconds), "" },
                }
            end),
            _.when(not server.is_installed, {
                { "filetypes", "LspInstallerMuted" },
                { server.metadata.filetypes, "" },
            }),
            _.when(server.is_installed, {
                { "install dir", "LspInstallerMuted" },
                { server.metadata.install_dir, "String" },
            }),
            {
                { "homepage", "LspInstallerMuted" },
                server.metadata.homepage and { server.metadata.homepage, "LspInstallerLink" } or {
                    "-",
                    "LspInstallerMuted",
                },
            }
        )),
        Ui.When(server.schema, function()
            return Ui.Node {
                Ui.EmptyLine(),
                Ui.HlTextNode {
                    {
                        {
                            ("%s Server configuration schema"):format(server.has_expanded_schema and "↓" or "→"),
                            "LspInstallerLabel",
                        },
                        {
                            (" (press enter to %s)"):format(server.has_expanded_schema and "collapse" or "expand"),
                            "Comment",
                        },
                    },
                },
                Ui.Keybind("<CR>", "TOGGLE_SERVER_SETTINGS_SCHEMA", { server.name }),
                Ui.When(server.has_expanded_schema, function()
                    return Indent {
                        Ui.HlTextNode {
                            {
                                {
                                    "This is a read-only representation of the settings this server accepts. Note that some settings might not apply to neovim.",
                                    "LspInstallerMuted",
                                },
                            },
                            {
                                { "For information on how to customize these settings, see ", "LspInstallerMuted" },
                                { ":help lspconfig-setup", "LspInstallerHighlighted" },
                            },
                        },
                        Ui.EmptyLine(),
                        ServerSettingsSchema(server, server.schema),
                    }
                end),
                Ui.EmptyLine(),
            }
        end)
    ))
end

---@param packages OutdatedPackage[]
local function format_outdated_packages(packages)
    return table.concat(
        vim.tbl_map(function(package)
            return ("%s %s -> %s"):format(package.name, package.current_version, package.latest_version)
        end, packages),
        "\n"
    )
end

---@param servers ServerState[]
---@param props ServerGroupProps
local function InstalledServers(servers, props)
    return Ui.Node(_.map(
        ---@param server ServerState
        function(server)
            local is_expanded = props.expanded_server == server.name
            return Ui.Node {
                Ui.HlTextNode {
                    _.list_not_nil(
                        { settings.current.ui.icons.server_installed, "LspInstallerGreen" },
                        { " " .. server.name .. " ", "" },
                        { server.hints, "Comment" },
                        _.when(server.deprecated, { " deprecated", "LspInstallerOrange" })
                    ),
                },
                Ui.When(
                    #server.metadata.outdated_packages > 0,
                    Ui.DiagnosticsNode {
                        message = ("new version available, press %s to update \n"):format(
                            settings.current.ui.keymaps.update_server
                        ) .. format_outdated_packages(server.metadata.outdated_packages),
                        severity = vim.diagnostic.severity.INFO,
                        source = server.name,
                    }
                ),
                Ui.Keybind(settings.current.ui.keymaps.toggle_server_expand, "EXPAND_SERVER", { server.name }),
                Ui.Keybind(settings.current.ui.keymaps.update_server, "INSTALL_SERVER", { server.name }),
                Ui.Keybind(settings.current.ui.keymaps.check_server_version, "CHECK_SERVER_VERSION", { server.name }),
                Ui.Keybind(settings.current.ui.keymaps.uninstall_server, "UNINSTALL_SERVER", { server.name }),
                Ui.When(is_expanded, function()
                    return Indent {
                        ServerMetadata(server),
                    }
                end),
            }
        end,
        servers
    ))
end

---@param server ServerState
local function TailedOutput(server)
    return Ui.HlTextNode(_.map(function(line)
        return { { line, "LspInstallerMuted" } }
    end, server.installer.tailed_output))
end

---@param output string[]
---@return string
local function get_last_non_empty_line(output)
    for i = #output, 1, -1 do
        local line = output[i]
        if #line > 0 then
            return line
        end
    end
    return ""
end

---@param servers ServerState[]
local function PendingServers(servers)
    return Ui.Node(_.map(function(_server)
        ---@type ServerState
        local server = _server
        local has_failed = server.installer.has_run or server.uninstaller.has_run
        local note = has_failed and "(failed)" or (server.installer.is_queued and "(queued)" or "(installing)")
        return Ui.Node {
            Ui.HlTextNode {
                _.list_not_nil(
                    {
                        settings.current.ui.icons.server_pending,
                        has_failed and "LspInstallerError" or "LspInstallerOrange",
                    },
                    { " " .. server.name, server.installer.is_running and "" or "LspInstallerMuted" },
                    { " " .. note, "Comment" },
                    _.when(not has_failed, {
                        (" " .. get_last_non_empty_line(server.installer.tailed_output)),
                        "Comment",
                    })
                ),
            },
            Ui.Keybind(settings.current.ui.keymaps.install_server, "INSTALL_SERVER", { server.name }),
            Ui.When(has_failed, function()
                return Indent { Indent { TailedOutput(server) } }
            end),
            Ui.When(
                server.uninstaller.error,
                Indent {
                    Ui.HlTextNode { server.uninstaller.error, "Comment" },
                }
            ),
        }
    end, servers))
end

---@param servers ServerState[]
---@param props ServerGroupProps
local function UninstalledServers(servers, props)
    return Ui.Node(_.map(function(_server)
        ---@type ServerState
        local server = _server
        local is_prioritized = props.prioritized_servers[server.name]
        local is_expanded = props.expanded_server == server.name
        return Ui.Node {
            Ui.HlTextNode {
                _.list_not_nil(
                    {
                        settings.current.ui.icons.server_uninstalled,
                        is_prioritized and "LspInstallerHighlighted" or "LspInstallerMuted",
                    },
                    { " " .. server.name .. " ", "LspInstallerMuted" },
                    { server.hints, "Comment" },
                    _.when(server.uninstaller.has_run, { " (uninstalled) ", "Comment" }),
                    _.when(server.deprecated, { "deprecated ", "LspInstallerOrange" })
                ),
            },
            Ui.Keybind(settings.current.ui.keymaps.toggle_server_expand, "EXPAND_SERVER", { server.name }),
            Ui.Keybind(settings.current.ui.keymaps.install_server, "INSTALL_SERVER", { server.name }),
            Ui.When(is_expanded, function()
                return Indent {
                    ServerMetadata(server),
                }
            end),
        }
    end, servers))
end

---@alias ServerGroupProps {title: string, title_diagnostics: table|nil, subtitle: string|nil, hide_when_empty: boolean|nil, servers: ServerState[][], expanded_server: string|nil, renderer: fun(servers: ServerState[], props: ServerGroupProps)}

---@param props ServerGroupProps
local function ServerGroup(props)
    local total_server_count = 0
    local chunks = props.servers
    for i = 1, #chunks do
        local servers = chunks[i]
        total_server_count = total_server_count + #servers
    end

    return Ui.When(total_server_count > 0 or not props.hide_when_empty, function()
        return Ui.Node {
            Ui.EmptyLine(),
            ServerGroupHeading {
                title = props.title,
                diagnostics = props.title_diagnostics,
                subtitle = props.subtitle,
                count = total_server_count,
            },
            Indent(_.map(function(servers)
                return props.renderer(servers, props)
            end, props.servers)),
        }
    end)
end

---@param state StatusWinState
local function Servers(state)
    local grouped_servers = {
        installed = {},
        queued = {},
        session_installed = {},
        uninstall_failed = {},
        installing = {},
        install_failed = {},
        uninstalled_prioritized = {},
        uninstalled = {},
        session_uninstalled = {},
    }

    local servers, server_name_order, prioritized_servers, expanded_server =
        state.servers, state.server_name_order, state.prioritized_servers, state.expanded_server

    -- giggity
    for _, server_name in ipairs(server_name_order) do
        local server = servers[server_name]
        if server.installer.is_running then
            grouped_servers.installing[#grouped_servers.installing + 1] = server
        elseif server.installer.is_queued then
            grouped_servers.queued[#grouped_servers.queued + 1] = server
        elseif server.uninstaller.has_run then
            if server.uninstaller.error then
                grouped_servers.uninstall_failed[#grouped_servers.uninstall_failed + 1] = server
            else
                grouped_servers.session_uninstalled[#grouped_servers.session_uninstalled + 1] = server
            end
        elseif server.is_installed then
            if server.installer.has_run then
                grouped_servers.session_installed[#grouped_servers.session_installed + 1] = server
            else
                grouped_servers.installed[#grouped_servers.installed + 1] = server
            end
        elseif server.installer.has_run then
            grouped_servers.install_failed[#grouped_servers.install_failed + 1] = server
        else
            if prioritized_servers[server.name] then
                grouped_servers.uninstalled_prioritized[#grouped_servers.uninstalled_prioritized + 1] = server
            else
                grouped_servers.uninstalled[#grouped_servers.uninstalled + 1] = server
            end
        end
    end

    return Ui.Node {
        ServerGroup {
            title = "Installed servers",
            title_diagnostics = state.has_outdated_servers and {
                severity = vim.diagnostic.severity.INFO,
                message = ("press %s to update all outdated servers"):format(
                    settings.current.ui.keymaps.update_all_servers
                ),
            } or nil,
            subtitle = state.server_version_check_completed_percentage ~= nil and {
                {
                    "checking for new versions ",
                    "Comment",
                },
                {
                    state.server_version_check_completed_percentage .. "%",
                    state.server_version_check_completed_percentage == 100 and "LspInstallerVersionCheckLoaderDone"
                        or "LspInstallerVersionCheckLoader",
                },
                {
                    string.rep(" ", math.floor(state.server_version_check_completed_percentage / 5)),
                    state.server_version_check_completed_percentage == 100 and "LspInstallerVersionCheckLoaderDone"
                        or "LspInstallerVersionCheckLoader",
                },
            },
            renderer = InstalledServers,
            servers = { grouped_servers.session_installed, grouped_servers.installed },
            expanded_server = expanded_server,
        },
        ServerGroup {
            title = "Pending servers",
            hide_when_empty = true,
            renderer = PendingServers,
            servers = {
                grouped_servers.installing,
                grouped_servers.queued,
                grouped_servers.install_failed,
                grouped_servers.uninstall_failed,
            },
            expanded_server = expanded_server,
        },
        ServerGroup {
            title = "Available servers",
            renderer = UninstalledServers,
            servers = {
                grouped_servers.session_uninstalled,
                grouped_servers.uninstalled_prioritized,
                grouped_servers.uninstalled,
            },
            expanded_server = expanded_server,
            prioritized_servers = prioritized_servers,
        },
    }
end

---@param server Server
local function create_initial_server_state(server)
    ---@class ServerState
    local server_state = {
        name = server.name,
        is_installed = server:is_installed(),
        deprecated = server.deprecated,
        hints = tostring(ServerHints.new(server)),
        expanded_schema_properties = {},
        has_expanded_schema = false,
        installed_version = nil, -- lazy
        installed_version_err = nil, -- lazy
        ---@type table
        schema = nil, -- lazy
        metadata = {
            homepage = server.homepage,
            ---@type number
            install_timestamp_seconds = nil, -- lazy
            install_dir = vim.fn.fnamemodify(server.root_dir, ":~"),
            filetypes = table.concat(server:get_supported_filetypes(), ", "),
            ---@type OutdatedPackage[]
            outdated_packages = {},
        },
        installer = {
            is_queued = false,
            is_running = false,
            has_run = false,
            tailed_output = { "" },
        },
        uninstaller = {
            has_run = false,
            error = nil,
        },
    }
    return server_state
end

local function normalize_chunks_line_endings(chunk, dest)
    local chunk_lines = vim.split(chunk, "\n")
    dest[#dest] = dest[#dest] .. chunk_lines[1]
    for i = 2, #chunk_lines do
        dest[#dest + 1] = chunk_lines[i]
    end
end

local function init(all_servers)
    local filetype_map = require "nvim-lsp-installer._generated.filetype_map"
    local window = display.new_view_only_win "LSP servers"

    log.trace "Initializing status window"

    window.view(
        --- @param state StatusWinState
        function(state)
            return Indent {
                Ui.Keybind(HELP_KEYMAP, "TOGGLE_HELP", nil, true),
                Ui.Keybind(CLOSE_WINDOW_KEYMAP_1, "CLOSE_WINDOW", nil, true),
                Ui.Keybind(CLOSE_WINDOW_KEYMAP_2, "CLOSE_WINDOW", nil, true),
                Ui.Keybind(settings.current.ui.keymaps.check_outdated_servers, "CHECK_OUTDATED_SERVERS", nil, true),
                Ui.Keybind(settings.current.ui.keymaps.update_all_servers, "UPDATE_ALL_SERVERS", nil, true),
                Header {
                    is_showing_help = state.is_showing_help,
                    help_command_text = state.help_command_text,
                },
                Ui.When(state.is_showing_help, function()
                    return Help(state.is_current_settings_expanded, state.vader_saber_ticks)
                end),
                Ui.When(not state.is_showing_help, function()
                    return Servers(state)
                end),
            }
        end
    )

    ---@type table<string, ServerState>
    local servers = {}
    ---@type string[]
    local server_name_order = {}
    for i = 1, #all_servers do
        local server = all_servers[i]
        servers[server.name] = create_initial_server_state(server)
        server_name_order[#server_name_order + 1] = server.name
    end

    table.sort(server_name_order)

    ---@class StatusWinState
    ---@field prioritized_servers string[]
    local initial_state = {
        server_name_order = server_name_order,
        servers = servers,
        server_version_check_completed_percentage = nil,
        has_outdated_servers = false,
        is_showing_help = false,
        is_current_settings_expanded = false,
        prioritized_servers = {},
        expanded_server = nil,
        help_command_text = "", -- for "animating" the ":help" text when toggling the help window
        vader_saber_ticks = 0, -- for "animating" the cowthvader lightsaber
    }

    local mutate_state_generic, get_state_generic = window.init(initial_state)
    -- Generics don't really work with higher-order functions so we cast it here.
    ---@type fun(mutate_fn: fun(current_state: StatusWinState))
    local mutate_state = mutate_state_generic
    ---@type fun(): StatusWinState
    local get_state = get_state_generic

    local async_populate_server_metadata = a.scope(function(server_name)
        a.scheduler()
        local ok, server = lsp_servers.get_server(server_name)
        if not ok then
            return log.warn("Unable to get server when populating metadata.", server_name)
        end
        local fstat_ok, fstat = pcall(fs.async.fstat, server.root_dir)
        mutate_state(function(state)
            if fstat_ok then
                state.servers[server.name].metadata.install_timestamp_seconds = fstat.mtime.sec
            end
            state.servers[server.name].schema = server:get_settings_schema()
        end)
        local version = version_check.check_server_version(server)
        mutate_state(function(state)
            if version:is_success() then
                state.servers[server.name].installed_version = version:get_or_nil()
                state.servers[server.name].installed_version_err = nil
            else
                state.servers[server.name].installed_version_err = true
            end
        end)
    end)

    ---@param server_name string
    local function expand_server(server_name)
        mutate_state(function(state)
            local should_expand = state.expanded_server ~= server_name
            state.expanded_server = should_expand and server_name or nil
            if should_expand then
                async_populate_server_metadata(server_name)
            end
        end)
    end

    ---@param server Server
    ---@param requested_version string|nil
    ---@param on_complete fun()
    local function start_install(server, requested_version, on_complete)
        mutate_state(function(state)
            state.servers[server.name].installer.is_queued = false
            state.servers[server.name].installer.is_running = true
        end)

        log.fmt_info("Starting install server_name=%s, requested_version=%s", server.name, requested_version or "")

        server:install_attached({
            requested_server_version = requested_version,
            stdio_sink = {
                stdout = function(chunk)
                    mutate_state(function(state)
                        local tailed_output = state.servers[server.name].installer.tailed_output
                        normalize_chunks_line_endings(chunk, tailed_output)
                    end)
                end,
                stderr = function(chunk)
                    mutate_state(function(state)
                        local tailed_output = state.servers[server.name].installer.tailed_output
                        normalize_chunks_line_endings(chunk, tailed_output)
                    end)
                end,
            },
        }, function(success)
            log.fmt_info("Installation completed server_name=%s, success=%s", server.name, success)
            mutate_state(function(state)
                if success then
                    -- release stdout/err output table.. hopefully ¯\_(ツ)_/¯
                    state.servers[server.name].installer.tailed_output = { "" }
                end
                state.servers[server.name].is_installed = success
                state.servers[server.name].installer.is_running = false
                state.servers[server.name].installer.has_run = true
                if not state.expanded_server then
                    -- Only automatically expand the server upon installation if none is already expanded, for UX reasons
                    expand_server(server.name)
                elseif state.expanded_server == server.name then
                    -- Refresh server metadata
                    async_populate_server_metadata(server.name)
                end
            end)
            on_complete()
        end)
    end

    -- We have a queue because installers have a tendency to hog resources.
    local job_pool = JobExecutionPool:new {
        size = settings.current.max_concurrent_installers,
    }
    ---@param server Server
    ---@param version string|nil
    local function install_server(server, version)
        log.fmt_debug("Queuing server=%s, version=%s for installation", server.name, version or "")
        local server_state = get_state().servers[server.name]
        if server_state and (server_state.installer.is_running or server_state.installer.is_queued) then
            log.debug("Installer is already queued/running", server.name)
            return
        end
        mutate_state(function(state)
            -- reset state
            state.servers[server.name] = create_initial_server_state(server)
            state.servers[server.name].installer.is_queued = true
        end)
        job_pool:supply(function(cb)
            start_install(server, version, cb)
        end)
    end

    ---@param server Server
    local function uninstall_server(server)
        local server_state = get_state().servers[server.name]
        if server_state and (server_state.installer.is_running or server_state.installer.is_queued) then
            log.debug("Installer is already queued/running", server.name)
            return
        end

        local is_uninstalled, err = pcall(server.uninstall, server)
        mutate_state(function(state)
            -- reset state
            state.servers[server.name] = create_initial_server_state(server)
            if is_uninstalled then
                state.servers[server.name].is_installed = false
            end
            state.servers[server.name].uninstaller.has_run = true
            state.servers[server.name].uninstaller.error = err
        end)
    end

    local function mark_all_servers_uninstalled()
        mutate_state(function(state)
            for _, server_name in ipairs(lsp_servers.get_available_server_names()) do
                if state.servers[server_name].is_installed then
                    state.servers[server_name].is_installed = false
                    state.servers[server_name].uninstaller.has_run = true
                end
            end
        end)
    end

    local make_animation = function(opts)
        local animation_fn = opts[1]
        local is_animating = false
        local start_animation = function()
            if is_animating then
                return
            end
            local tick, start

            tick = function(current_tick)
                animation_fn(current_tick)
                if current_tick < opts.end_tick then
                    vim.defer_fn(function()
                        tick(current_tick + 1)
                    end, opts.delay_ms)
                else
                    is_animating = false
                    if opts.iteration_delay_ms then
                        start(opts.iteration_delay_ms)
                    end
                end
            end

            start = function(delay_ms)
                is_animating = true
                if delay_ms then
                    vim.defer_fn(function()
                        tick(opts.start_tick)
                    end, delay_ms)
                else
                    tick(opts.start_tick)
                end
            end

            start(opts.start_delay_ms)

            local function cancel()
                is_animating = false
            end

            return cancel
        end

        return start_animation
    end

    local start_help_command_animation
    do
        local help_command = ":help "
        local help_command_len = #help_command
        start_help_command_animation = make_animation {
            function(tick)
                mutate_state(function(state)
                    state.help_command_text = help_command:sub(help_command_len - tick, help_command_len)
                end)
            end,
            start_tick = 0,
            end_tick = help_command_len,
            delay_ms = 80,
        }
    end

    local start_vader_saber_animation = make_animation {
        function(tick)
            mutate_state(function(state)
                state.vader_saber_ticks = tick
            end)
        end,
        start_tick = 0,
        end_tick = 3,
        delay_ms = 350,
        iteration_delay_ms = 10000,
        start_delay_ms = 1000,
    }

    local function close()
        if window then
            window.close()
        end
    end

    local has_opened = false

    local function identify_outdated_servers(servers)
        -- Sort servers the same way as in the UI, gives a more structured impression
        table.sort(servers, function(a, b)
            return a.name < b.name
        end)
        if #servers > 0 then
            mutate_state(function(state)
                state.has_outdated_servers = false
                state.server_version_check_completed_percentage = 0
            end)
        end
        local has_outdated_servers = false
        outdated_servers.identify_outdated_servers(servers, function(check_result, progress)
            mutate_state(function(state)
                local completed_percentage = progress.completed / progress.total
                state.server_version_check_completed_percentage = math.floor(completed_percentage * 100)
                if completed_percentage == 1 then
                    vim.defer_fn(function()
                        mutate_state(function(state)
                            state.has_outdated_servers = has_outdated_servers
                            state.server_version_check_completed_percentage = nil
                        end)
                    end, 700)
                end

                if check_result.success and check_result:has_outdated_packages() then
                    has_outdated_servers = true
                    state.servers[check_result.server.name].metadata.outdated_packages = check_result.outdated_packages
                end
            end)
        end)
    end

    local function open()
        local open_filetypes = {}
        for _, open_bufnr in ipairs(vim.api.nvim_list_bufs()) do
            table.insert(open_filetypes, vim.api.nvim_buf_get_option(open_bufnr, "filetype"))
        end

        local prioritized_servers = {}
        for _, filetype in ipairs(open_filetypes) do
            if filetype_map[filetype] then
                vim.list_extend(prioritized_servers, filetype_map[filetype])
            end
        end

        mutate_state(function(state)
            state.is_showing_help = false
            state.prioritized_servers = _.set_of(prioritized_servers)
        end)

        if not has_opened and settings.current.ui.check_outdated_servers_on_open then
            -- Only do this automatically once - when opening the window the first time
            vim.defer_fn(function()
                identify_outdated_servers(lsp_servers.get_installed_servers())
            end, 100)
        end

        window.open {
            highlight_groups = {
                "hi def LspInstallerHeader gui=bold guifg=#222222 guibg=#DCA561",
                "hi def LspInstallerHeaderHelp gui=bold guifg=#222222 guibg=#56B6C2",
                "hi def LspInstallerServerExpanded gui=italic",
                "hi def LspInstallerHeading gui=bold",
                "hi def LspInstallerGreen guifg=#a3be8c",
                "hi def LspInstallerVaderSaber guifg=#f44747 gui=bold",
                "hi def LspInstallerOrange ctermfg=222 guifg=#DCA561",
                "hi def LspInstallerMuted guifg=#888888 ctermfg=144",
                "hi def LspInstallerLabel gui=bold",
                "hi def LspInstallerError ctermfg=203 guifg=#f44747",
                "hi def LspInstallerHighlighted guifg=#56B6C2",
                "hi def LspInstallerVersionCheckLoader gui=bold guifg=#222222 guibg=#888888",
                "hi def LspInstallerVersionCheckLoaderDone gui=bold guifg=#222222 guibg=#a3be8c",
                "hi def link LspInstallerLink LspInstallerHighlighted",
            },
            effects = {
                ["TOGGLE_HELP"] = function()
                    if not get_state().is_showing_help then
                        start_help_command_animation()
                        start_vader_saber_animation()
                        window.set_cursor { 1, 1 }
                    end
                    mutate_state(function(state)
                        state.is_showing_help = not state.is_showing_help
                    end)
                end,
                ["CLOSE_WINDOW"] = function()
                    close()
                end,
                ["CHECK_OUTDATED_SERVERS"] = function()
                    vim.schedule(function()
                        identify_outdated_servers(lsp_servers.get_installed_servers())
                    end)
                end,
                ["CHECK_SERVER_VERSION"] = function(e)
                    local server_name = e.payload[1]
                    local ok, server = lsp_servers.get_server(server_name)
                    if ok then
                        identify_outdated_servers { server }
                    end
                end,
                ["TOGGLE_EXPAND_CURRENT_SETTINGS"] = function()
                    mutate_state(function(state)
                        state.is_current_settings_expanded = not state.is_current_settings_expanded
                    end)
                end,
                ["EXPAND_SERVER"] = function(e)
                    local server_name = e.payload[1]
                    expand_server(server_name)
                end,
                ["TOGGLE_SERVER_SETTINGS_SCHEMA"] = function(e)
                    local server_name = e.payload[1]
                    mutate_state(function(state)
                        state.servers[server_name].has_expanded_schema =
                            not state.servers[server_name].has_expanded_schema
                    end)
                end,
                ["TOGGLE_SERVER_SCHEMA_SETTING"] = function(e)
                    local server_name = e.payload.name
                    local key = e.payload.key
                    mutate_state(function(state)
                        state.servers[server_name].expanded_schema_properties[key] =
                            not state.servers[server_name].expanded_schema_properties[key]
                    end)
                end,
                ["INSTALL_SERVER"] = function(e)
                    mutate_state(function(state)
                        state.has_outdated_servers = false
                    end)
                    local server_name = e.payload[1]
                    local ok, server = lsp_servers.get_server(server_name)
                    if ok then
                        install_server(server, nil)
                    end
                end,
                ["UPDATE_ALL_SERVERS"] = function()
                    mutate_state(function(state)
                        state.has_outdated_servers = false
                    end)
                    local installed_servers = lsp_servers.get_installed_servers()
                    local state = get_state()
                    local outdated_servers = vim.tbl_filter(function(server)
                        return #state.servers[server.name].metadata.outdated_packages > 0
                    end, installed_servers)
                    -- Install servers that are identified as outdated, otherwise update all installed servers.
                    local servers_to_update = #outdated_servers > 0 and outdated_servers or installed_servers
                    for _, server in ipairs(servers_to_update) do
                        install_server(server, nil)
                    end
                end,
                ["UNINSTALL_SERVER"] = function(e)
                    mutate_state(function(state)
                        state.has_outdated_servers = false
                    end)
                    local server_name = e.payload[1]
                    local ok, server = lsp_servers.get_server(server_name)
                    if ok then
                        uninstall_server(server)
                    end
                end,
                ["REPLACE_SERVER"] = function(e)
                    mutate_state(function(state)
                        state.has_outdated_servers = false
                    end)
                    local old_server_name, new_server_name = e.payload[1], e.payload[2]
                    local old_ok, old_server = lsp_servers.get_server(old_server_name)
                    local new_ok, new_server = lsp_servers.get_server(new_server_name)
                    if old_ok and new_ok then
                        uninstall_server(old_server)
                        install_server(new_server)
                    end
                end,
            },
        }
        has_opened = true
    end

    return {
        open = open,
        close = close,
        install_server = install_server,
        uninstall_server = uninstall_server,
        mark_all_servers_uninstalled = mark_all_servers_uninstalled,
    }
end

local win
return function()
    if win then
        return win
    end
    win = init(lsp_servers.get_available_servers())
    return win
end
