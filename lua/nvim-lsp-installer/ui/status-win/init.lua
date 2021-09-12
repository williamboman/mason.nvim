local Ui = require "nvim-lsp-installer.ui"
local fs = require "nvim-lsp-installer.fs"
local log = require "nvim-lsp-installer.log"
local Data = require "nvim-lsp-installer.data"
local display = require "nvim-lsp-installer.ui.display"

local function ServerGroupHeading(props)
    return Ui.HlTextNode {
        { { props.title, props.highlight or "LspInstallerHeading" }, { (" (%d)"):format(props.count), "Comment" } },
    }
end

local function Indent(children)
    return Ui.CascadingStyleNode({ Ui.CascadingStyle.INDENT }, children)
end

local function Header()
    return Ui.CascadingStyleNode({ Ui.CascadingStyle.CENTERED }, {
        Ui.HlTextNode {
            { { "nvim-lsp-installer", "LspInstallerHeader" } },
            { { "https://github.com/williamboman/nvim-lsp-installer", "LspInstallerLink" } },
        },
    })
end

-- TODO make configurable
local LIST_ICON = "◍"

local Seconds = {
    DAY = 86400, -- 60 * 60 * 24
    WEEK = 604800, -- 60 * 60 * 24 * 7
    MONTH = 2419200, -- 60 * 60 * 24 * 7 * 4
    YEAR = 29030400, -- 60 * 60 * 24 * 7 * 4 * 12
}

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
        return ("%d months ago"):format(math.floor((delta / 2419200) + 0.5))
    else
        return "more than a year ago"
    end
end

local function InstalledServers(servers)
    return Ui.Node(Data.list_map(function(server)
        return Ui.Node {
            Ui.HlTextNode {
                {
                    { LIST_ICON, "LspInstallerGreen" },
                    { " " .. server.name, "Normal" },
                    {
                        (" installed %s"):format(get_relative_install_time(server.creation_time)),
                        "Comment",
                    },
                },
            },
        }
    end, servers))
end

local function TailedOutput(server)
    return Ui.HlTextNode(Data.list_map(function(line)
        return { { line, "LspInstallerGray" } }
    end, server.installer.tailed_output))
end

local function get_last_non_empty_line(output)
    for i = #output, 1, -1 do
        local line = output[i]
        if #line > 0 then
            return line
        end
    end
    return ""
end

local function PendingServers(servers)
    return Ui.Node(Data.list_map(function(server)
        local has_failed = server.installer.has_run or server.uninstaller.has_run
        local note = has_failed and "(failed)" or (server.installer.is_queued and "(queued)" or "(running)")
        return Ui.Node {
            Ui.HlTextNode {
                {
                    { LIST_ICON, has_failed and "LspInstallerError" or "LspInstallerOrange" },
                    { " " .. server.name, server.installer.is_running and "Normal" or "LspInstallerGray" },
                    { " " .. note, "Comment" },
                    { has_failed and "" or (" " .. get_last_non_empty_line(server.installer.tailed_output)), "Comment" },
                },
            },
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

local function UninstalledServers(servers)
    return Ui.Node(Data.list_map(function(server)
        return Ui.Node {
            Ui.HlTextNode {
                {
                    { LIST_ICON, "LspInstallerGray" },
                    { " " .. server.name, "Comment" },
                    { server.uninstaller.has_run and " (just uninstalled)" or "", "Comment" },
                },
            },
        }
    end, servers))
end

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
                return props.renderer(servers)
            end, props.servers)),
        }
    end)
end

local function Servers(servers)
    local grouped_servers = {
        installed = {},
        queued = {},
        session_installed = {},
        uninstall_failed = {},
        installing = {},
        install_failed = {},
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
            grouped_servers.uninstalled[#grouped_servers.uninstalled + 1] = server
        end
    end

    return Ui.Node {
        ServerGroup {
            title = "Installed servers",
            renderer = InstalledServers,
            servers = { grouped_servers.session_installed, grouped_servers.installed },
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
        },
        ServerGroup {
            title = "Available servers",
            renderer = UninstalledServers,
            servers = { grouped_servers.session_uninstalled, grouped_servers.uninstalled },
        },
    }
end

local function create_server_state(server)
    local ok, fstat = pcall(fs.fstat, server.root_dir)
    local creation_time
    if ok then
        creation_time = fstat.mtime.sec
    end

    return {
        name = server.name,
        is_installed = server:is_installed(),
        creation_time = creation_time,
        installer = {
            is_queued = false,
            is_running = false,
            has_run = false,
            tailed_output = {},
        },
        uninstaller = { has_run = false, error = nil },
    }
end

local function init(all_servers)
    local window = display.new_view_only_win "LSP servers"

    window.view(function(state)
        return Ui.Node {
            Header(),
            Servers(state.servers),
        }
    end)

    local servers = {}
    for i = 1, #all_servers do
        local server = all_servers[i]
        servers[server.name] = create_server_state(server)
    end

    local mutate_state, get_state = window.init {
        servers = servers,
    }

    local function open()
        window.open {
            win_width = 95,
            highlight_groups = {
                "hi def LspInstallerHeader gui=bold guifg=#ebcb8b",
                "hi def link LspInstallerLink Comment",
                "hi def LspInstallerHeading gui=bold",
                "hi def LspInstallerGreen guifg=#a3be8c",
                "hi def LspInstallerOrange ctermfg=222 guifg=#ebcb8b",
                "hi def LspInstallerGray guifg=#888888 ctermfg=144",
                "hi def LspInstallerError ctermfg=203 guifg=#f44747",
            },
        }
    end

    local function start_install(server, on_complete)
        mutate_state(function(state)
            state.servers[server.name].installer.is_queued = false
            state.servers[server.name].installer.is_running = true
        end)

        server:install_attached({
            stdio_sink = {
                stdout = function(line)
                    mutate_state(function(state)
                        local tailed_output = state.servers[server.name].installer.tailed_output
                        tailed_output[#tailed_output + 1] = line
                    end)
                end,
                stderr = function(line)
                    mutate_state(function(state)
                        local tailed_output = state.servers[server.name].installer.tailed_output
                        tailed_output[#tailed_output + 1] = line
                    end)
                end,
            },
        }, function(success)
            mutate_state(function(state)
                if success then
                    -- release stdout/err output table.. hopefully ¯\_(ツ)_/¯
                    state.servers[server.name].installer.tailed_output = {}
                end
                state.servers[server.name].is_installed = success
                state.servers[server.name].creation_time = os.time()
                state.servers[server.name].installer.is_running = false
                state.servers[server.name].installer.has_run = true
            end)
            on_complete()
        end)
    end

    -- We have a queue because installers have a tendency to hog resources.
    local queue = (function()
        local max_running = 2
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

        return function(server)
            q[#q + 1] = server
            check_queue()
        end
    end)()

    return {
        open = open,
        install_server = function(server)
            log.debug { "installing server", server }
            local server_state = get_state().servers[server.name]
            if server_state and (server_state.installer.is_running or server_state.installer.is_queued) then
                log.debug { "Installer is already queued/running", server.name }
                return
            end
            mutate_state(function(state)
                -- reset state
                state.servers[server.name] = create_server_state(server)
                state.servers[server.name].installer.is_queued = true
            end)
            queue(server)
        end,
        uninstall_server = function(server)
            local server_state = get_state().servers[server.name]
            if server_state and (server_state.installer.is_running or server_state.installer.is_queued) then
                log.debug { "Installer is already queued/running", server.name }
                return
            end

            local is_uninstalled, err = pcall(server.uninstall, server)
            mutate_state(function(state)
                state.servers[server.name] = create_server_state(server)
                if is_uninstalled then
                    state.servers[server.name].is_installed = false
                end
                state.servers[server.name].uninstaller.has_run = true
                state.servers[server.name].uninstaller.error = err
            end)
        end,
    }
end

local win
return function()
    if win then
        return win
    end
    local servers = require "nvim-lsp-installer.servers"
    win = init(servers.get_available_servers())
    return win
end
