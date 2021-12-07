local Ui = require "nvim-lsp-installer.ui"
local fs = require "nvim-lsp-installer.fs"
local log = require "nvim-lsp-installer.log"
local Data = require "nvim-lsp-installer.data"
local display = require "nvim-lsp-installer.ui.display"
local settings = require "nvim-lsp-installer.settings"
local lsp_servers = require "nvim-lsp-installer.servers"

local HELP_KEYMAP = "?"
local CLOSE_WINDOW_KEYMAP_1 = "<Esc>"
local CLOSE_WINDOW_KEYMAP_2 = "q"

---@param props {title: string, count: number}
local function ServerGroupHeading(props)
    return Ui.HlTextNode {
        { { props.title, props.highlight or "LspInstallerHeading" }, { (" (%d)"):format(props.count), "Comment" } },
    }
end

local function Indent(children)
    return Ui.CascadingStyleNode({ "INDENT" }, children)
end

local create_vader = Data.memoize(
    ---@param saber_ticks number
    function(saber_ticks)
    -- stylua: ignore start
    return {
        { { [[ _______________________________________________________________________ ]], "LspInstallerMuted" } },
        { { [[ < Help sponsor Neovim development! ]], "LspInstallerMuted" }, { "https://github.com/sponsors/neovim", "LspInstallerHighlighted"}, {[[ > ]], "LspInstallerMuted" } },
        { { [[ ----------------------------------------------------------------------- ]], "LspInstallerMuted" } },
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
            Data.list_map(function(keymap_tuple)
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
            {
                {
                    ("%s Current settings"):format(is_current_settings_expanded and "v" or ">"),
                    "LspInstallerLabel",
                },
                { " :help nvim-lsp-installer-settings", "LspInstallerHighlighted" },
            },
        },
        Ui.Keybind("<CR>", "TOGGLE_EXPAND_CURRENT_SETTINGS", nil),
        Ui.When(is_current_settings_expanded, function()
            local settings_split_by_newline = vim.split(vim.inspect(settings.current), "\n")
            local current_settings = Data.list_map(function(line)
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
                { props.is_showing_help and props.help_command_text or "", "LspInstallerHighlighted" },
                {
                    props.is_showing_help and "nvim-lsp-installer" .. (" "):rep(#props.help_command_text)
                        or "nvim-lsp-installer",
                    props.is_showing_help and "LspInstallerHighlighted" or "LspInstallerHeader",
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

local Seconds = {
    DAY = 86400, -- 60 * 60 * 24
    WEEK = 604800, -- 60 * 60 * 24 * 7
    MONTH = 2419200, -- 60 * 60 * 24 * 7 * 4
    YEAR = 29030400, -- 60 * 60 * 24 * 7 * 4 * 12
}

---@param time number
local function get_relative_install_time(time)
    local now = os.time()
    local delta = math.max(now - time, 0)
    if delta < Seconds.DAY then
        return "today"
    elseif delta < Seconds.WEEK then
        return "this week"
    elseif delta < Seconds.MONTH then
        return "this month"
    elseif delta < (Seconds.MONTH * 2) then
        return "last month"
    elseif delta < Seconds.YEAR then
        return ("%d months ago"):format(math.floor((delta / Seconds.MONTH) + 0.5))
    else
        return "more than a year ago"
    end
end

---@param server ServerState
local function ServerMetadata(server)
    return Ui.Node(Data.list_not_nil(
        Data.lazy(server.is_installed and server.deprecated, function()
            return Ui.Node(Data.list_not_nil(
                Ui.HlTextNode { server.deprecated.message, "Comment" },
                Data.lazy(server.deprecated.replace_with, function()
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
        Ui.Table(Data.list_not_nil(
            Data.lazy(server.metadata.install_timestamp_seconds, function()
                return {
                    { "last updated", "LspInstallerMuted" },
                    { get_relative_install_time(server.metadata.install_timestamp_seconds), "" },
                }
            end),
            {
                { "filetypes", "LspInstallerMuted" },
                { server.metadata.filetypes, "" },
            },
            Data.when(server.is_installed, {
                { "path", "LspInstallerMuted" },
                { server.metadata.install_dir, "String" },
            }),
            {
                { "homepage", "LspInstallerMuted" },
                server.metadata.homepage and { server.metadata.homepage, "LspInstallerLink" } or {
                    "-",
                    "LspInstallerMuted",
                },
            }
        ))
    ))
end

---@param servers ServerState[]
---@param props ServerGroupProps
local function InstalledServers(servers, props)
    return Ui.Node(Data.list_map(function(server)
        local is_expanded = props.expanded_server == server.name
        return Ui.Node {
            Ui.HlTextNode {
                Data.list_not_nil(
                    { settings.current.ui.icons.server_installed, "LspInstallerGreen" },
                    { " " .. server.name, "" },
                    Data.when(server.deprecated, { " deprecated", "LspInstallerOrange" })
                ),
            },
            Ui.Keybind(settings.current.ui.keymaps.toggle_server_expand, "EXPAND_SERVER", { server.name }),
            Ui.Keybind(settings.current.ui.keymaps.update_server, "INSTALL_SERVER", { server.name }),
            Ui.Keybind(settings.current.ui.keymaps.uninstall_server, "UNINSTALL_SERVER", { server.name }),
            Ui.When(is_expanded, function()
                return Indent {
                    ServerMetadata(server),
                }
            end),
        }
    end, servers))
end

---@param server ServerState
local function TailedOutput(server)
    return Ui.HlTextNode(Data.list_map(function(line)
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
    return Ui.Node(Data.list_map(function(_server)
        ---@type ServerState
        local server = _server
        local has_failed = server.installer.has_run or server.uninstaller.has_run
        local note = has_failed and "(failed)" or (server.installer.is_queued and "(queued)" or "(installing)")
        return Ui.Node {
            Ui.HlTextNode {
                Data.list_not_nil(
                    {
                        settings.current.ui.icons.server_pending,
                        has_failed and "LspInstallerError" or "LspInstallerOrange",
                    },
                    { " " .. server.name, server.installer.is_running and "" or "LspInstallerMuted" },
                    { " " .. note, "Comment" },
                    Data.when(not has_failed, {
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
    return Ui.Node(Data.list_map(function(server)
        local is_prioritized = props.prioritized_servers[server.name]
        local is_expanded = props.expanded_server == server.name
        return Ui.Node {
            Ui.HlTextNode {
                Data.list_not_nil(
                    {
                        settings.current.ui.icons.server_uninstalled,
                        is_prioritized and "LspInstallerHighlighted" or "LspInstallerMuted",
                    },
                    { " " .. server.name, "LspInstallerMuted" },
                    Data.when(server.uninstaller.has_run, { " (uninstalled)", "Comment" }),
                    Data.when(server.deprecated, { " deprecated", "LspInstallerOrange" })
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

---@alias ServerGroupProps {title: string, hide_when_empty: boolean|nil, servers: ServerState[][], expanded_server: string|nil, renderer: fun(servers: ServerState[], props: ServerGroupProps)}

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
                count = total_server_count,
            },
            Indent(Data.list_map(function(servers)
                return props.renderer(servers, props)
            end, props.servers)),
        }
    end)
end

---@param servers table<string, ServerState>
---@param expanded_server string|nil
---@param prioritized_servers string[]
local function Servers(servers, expanded_server, prioritized_servers)
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

    -- giggity
    for _, server in pairs(servers) do
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
        metadata = {
            homepage = server.homepage,
            install_timestamp_seconds = nil, -- lazy
            install_dir = vim.fn.fnamemodify(server.root_dir, ":~"),
            filetypes = table.concat(server:get_supported_filetypes(), ", "),
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

    window.view(
        --- @param state StatusWinState
        function(state)
            return Indent {
                Ui.Keybind(HELP_KEYMAP, "TOGGLE_HELP", nil, true),
                Ui.Keybind(CLOSE_WINDOW_KEYMAP_1, "CLOSE_WINDOW", nil, true),
                Ui.Keybind(CLOSE_WINDOW_KEYMAP_2, "CLOSE_WINDOW", nil, true),
                Header {
                    is_showing_help = state.is_showing_help,
                    help_command_text = state.help_command_text,
                },
                Ui.When(state.is_showing_help, function()
                    return Help(state.is_current_settings_expanded, state.vader_saber_ticks)
                end),
                Ui.When(not state.is_showing_help, function()
                    return Servers(state.servers, state.expanded_server, state.prioritized_servers)
                end),
            }
        end
    )

    ---@type table<string, ServerState>
    local servers = {}
    for i = 1, #all_servers do
        local server = all_servers[i]
        servers[server.name] = create_initial_server_state(server)
    end

    ---@class StatusWinState
    ---@field prioritized_servers string[]
    local initial_state = {
        servers = servers,
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

    -- TODO: memoize or throttle.. or cache. Do something. Also, as opposed to what the naming currently suggests, this
    -- is not really doing anything async stuff, but will very likely do so in the future :tm:.
    local async_populate_server_metadata = vim.schedule_wrap(function(server_name)
        local ok, server = lsp_servers.get_server(server_name)
        if not ok then
            return log.warn("Unable to get server when populating metadata.", server_name)
        end
        local fstat_ok, fstat = pcall(fs.fstat, server.root_dir)
        mutate_state(function(state)
            if fstat_ok then
                state.servers[server.name].metadata.install_timestamp_seconds = fstat.mtime.sec
            end
        end)
    end)

    local function expand_server(server_name)
        mutate_state(function(state)
            local should_expand = state.expanded_server ~= server_name
            state.expanded_server = should_expand and server_name or nil
            if should_expand then
                async_populate_server_metadata(server_name)
            end
        end)
    end

    ---@alias ServerInstallTuple {[1]:Server, [2]: string|nil}

    ---@param server_tuple ServerInstallTuple
    ---@param on_complete fun()
    local function start_install(server_tuple, on_complete)
        local server, requested_version = server_tuple[1], server_tuple[2]
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
                    state.servers[server.name].installer.tailed_output = {}
                end
                state.servers[server.name].is_installed = success
                state.servers[server.name].installer.is_running = false
                state.servers[server.name].installer.has_run = true
            end)
            expand_server(server.name)
            on_complete()
        end)
    end

    -- We have a queue because installers have a tendency to hog resources.
    local queue
    do
        local max_running = settings.current.max_concurrent_installers
        ---@type ServerInstallTuple[]
        local q = {}
        local r = 0

        local check_queue
        check_queue = vim.schedule_wrap(function()
            if #q > 0 and r < max_running then
                local dequeued_server = table.remove(q, 1)
                r = r + 1
                start_install(dequeued_server, function()
                    r = r - 1
                    check_queue()
                end)
            end
        end)

        ---@param server Server
        ---@param version string|nil
        queue = function(server, version)
            q[#q + 1] = { server, version }
            check_queue()
        end
    end

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
        queue(server, version)
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
            state.prioritized_servers = Data.set_of(prioritized_servers)
        end)

        window.open {
            win_width = 95,
            highlight_groups = {
                "hi def LspInstallerHeader gui=bold guifg=#ebcb8b",
                "hi def LspInstallerServerExpanded gui=italic",
                "hi def LspInstallerHeading gui=bold",
                "hi def LspInstallerGreen guifg=#a3be8c",
                "hi def LspInstallerVaderSaber guifg=#f44747 gui=bold",
                "hi def LspInstallerOrange ctermfg=222 guifg=#ebcb8b",
                "hi def LspInstallerMuted guifg=#888888 ctermfg=144",
                "hi def LspInstallerLabel gui=bold",
                "hi def LspInstallerError ctermfg=203 guifg=#f44747",
                "hi def LspInstallerHighlighted guifg=#56B6C2",
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
                ["TOGGLE_EXPAND_CURRENT_SETTINGS"] = function()
                    mutate_state(function(state)
                        state.is_current_settings_expanded = not state.is_current_settings_expanded
                    end)
                end,
                ["EXPAND_SERVER"] = function(e)
                    local server_name = e.payload[1]
                    expand_server(server_name)
                end,
                ["INSTALL_SERVER"] = function(e)
                    local server_name = e.payload[1]
                    local ok, server = lsp_servers.get_server(server_name)
                    if ok then
                        install_server(server, nil)
                    end
                end,
                ["UNINSTALL_SERVER"] = function(e)
                    local server_name = e.payload[1]
                    local ok, server = lsp_servers.get_server(server_name)
                    if ok then
                        uninstall_server(server)
                    end
                end,
                ["REPLACE_SERVER"] = function(e)
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
