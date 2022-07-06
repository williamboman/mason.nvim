local Ui = require "mason.core.ui"
local p = require "mason.ui.palette"
local _ = require "mason.core.functional"
local settings = require "mason.settings"

local JsonSchema = require "mason.ui.components.json-schema"

---@param props { state: InstallerUiState, heading: INode, packages: Package[], list_item_renderer: (fun(package: Package): INode), hide_when_empty: boolean }
local function PackageListContainer(props)
    local items = {}
    for i = 1, #props.packages do
        local package = props.packages[i]
        if props.state.packages.visible[package.name] then
            items[#items + 1] = props.list_item_renderer(package)
        end
    end

    if props.hide_when_empty and #items == 0 then
        return Ui.Node {}
    end

    return Ui.Node {
        props.heading,
        Ui.VirtualTextNode { p.Comment(("(%d)"):format(#items)) },
        Ui.CascadingStyleNode({ "INDENT" }, items),
        Ui.When(
            #items == 0,
            Ui.CascadingStyleNode({ "CENTERED" }, {
                Ui.HlTextNode(p.Comment "No packages."),
            })
        ),
        Ui.EmptyLine(),
    }
end

---@param executables table<string, string> | nil
local function ExecutablesTable(executables)
    if not executables or _.size(executables) == 0 then
        return Ui.Node {}
    end
    local rows = {}
    for executable in pairs(executables) do
        table.insert(rows, { p.none "", p.Bold(executable) })
    end
    rows[1][1] = p.muted "executables"
    return rows
end

---@param state InstallerUiState
---@param package Package
---@param is_installed boolean
local function ExpandedPackageInfo(state, package, is_installed)
    local pkg_state = state.packages.states[package.name]
    return Ui.CascadingStyleNode({ "INDENT" }, {
        Ui.HlTextNode(p.Comment(package.spec.desc)),
        Ui.EmptyLine(),
        Ui.Table(_.concat(
            _.filter(_.identity, {
                is_installed and {
                    p.muted "installed version",
                    pkg_state.version and p.Bold(pkg_state.version)
                        or (pkg_state.is_checking_version and p.muted "Loading…" or p.muted "-"),
                },
                pkg_state.new_version and {
                    p.muted "latest version",
                    p.muted(pkg_state.new_version.latest_version),
                },
                {
                    p.muted "homepage",
                    package.spec.homepage and p.highlight(package.spec.homepage) or p.muted "-",
                },
                {
                    p.muted "languages",
                    #package.spec.languages > 0 and p.Bold(table.concat(package.spec.languages, ", ")) or p.muted "-",
                },
                {
                    p.muted "categories",
                    #package.spec.categories > 0 and p.Bold(table.concat(package.spec.categories, ", ")) or p.muted "-",
                },
            }),
            ExecutablesTable(is_installed and pkg_state.linked_executables or package.spec.executables)
        )),
        -- ExecutablesTable(is_installed and pkg_state.linked_executables or package.spec.executables),
        Ui.When(pkg_state.lsp_settings_schema, function()
            local has_expanded = pkg_state.expanded_json_schemas["lsp"]
            return Ui.Node {
                Ui.EmptyLine(),
                Ui.HlTextNode {
                    {
                        p.Bold(("%s LSP server configuration schema"):format(has_expanded and "↓" or "→")),
                        p.Comment((" (press enter to %s)"):format(has_expanded and "collapse" or "expand")),
                    },
                },
                Ui.Keybind(
                    settings.current.ui.keymaps.toggle_package_expand,
                    "TOGGLE_JSON_SCHEMA",
                    { package = package, schema_id = "lsp" }
                ),
                Ui.When(has_expanded, function()
                    return Ui.CascadingStyleNode({ "INDENT" }, {
                        Ui.HlTextNode(
                            p.muted "This is a read-only overview of the settings this server accepts. Note that some settings might not apply to neovim."
                        ),
                        Ui.EmptyLine(),
                        JsonSchema(package, "lsp", pkg_state, pkg_state.lsp_settings_schema),
                    })
                end),
            }
        end),
        Ui.EmptyLine(),
    })
end

---@param state InstallerUiState
---@param package Package
---@param opts { keybinds: KeybindHandlerNode[], icon: string[], is_installed: boolean }
local function PackageComponent(state, package, opts)
    local pkg_state = state.packages.states[package.name]
    local is_expanded = state.packages.expanded == package.name
    local label = is_expanded and p.Bold(" " .. package.name) or p.none(" " .. package.name)

    return Ui.Node {
        Ui.HlTextNode { { opts.icon, label } },
        Ui.StickyCursor { id = package.spec.name },
        Ui.When(pkg_state.is_checking_new_version, function()
            return Ui.VirtualTextNode { p.Comment " checking for new version…" }
        end),
        Ui.Keybind(settings.current.ui.keymaps.check_package_version, "CHECK_NEW_PACKAGE_VERSION", package),
        Ui.When(pkg_state.new_version, function()
            return Ui.DiagnosticsNode {
                message = ("new version available: %s %s -> %s"):format(
                    pkg_state.new_version.name,
                    pkg_state.new_version.current_version,
                    pkg_state.new_version.latest_version
                ),
                severity = vim.diagnostic.severity.INFO,
                source = pkg_state.new_version.name,
            }
        end),
        Ui.Node(opts.keybinds),
        Ui.When(is_expanded, function()
            return ExpandedPackageInfo(state, package, opts.is_installed)
        end),
    }
end

---@param state InstallerUiState
local function Installed(state)
    return Ui.Node {
        Ui.Keybind(
            settings.current.ui.keymaps.check_outdated_packages,
            "CHECK_NEW_VISIBLE_PACKAGE_VERSIONS",
            nil,
            true
        ),
        PackageListContainer {
            state = state,
            heading = Ui.Node {
                Ui.HlTextNode(p.heading "Installed"),
                Ui.When(state.packages.new_versions_check.is_checking, function()
                    local new_versions_check = state.packages.new_versions_check
                    local styling = new_versions_check.percentage_complete == 1 and p.highlight_block or p.muted_block
                    return Ui.VirtualTextNode {
                        p.Comment "checking for new package versions ",
                        styling(("%-4s"):format(math.floor(new_versions_check.percentage_complete * 100) .. "%")),
                        styling((" "):rep(new_versions_check.percentage_complete * 15)),
                    }
                end),
            },
            packages = state.packages.installed,
            ---@param package Package
            list_item_renderer = function(package)
                return PackageComponent(state, package, {
                    is_installed = true,
                    icon = p.highlight(settings.current.ui.icons.package_installed),
                    keybinds = {
                        Ui.Keybind(settings.current.ui.keymaps.update_package, "INSTALL_PACKAGE", package),
                        Ui.Keybind(settings.current.ui.keymaps.uninstall_package, "UNINSTALL_PACKAGE", package),
                        Ui.Keybind(settings.current.ui.keymaps.toggle_package_expand, "TOGGLE_EXPAND_PACKAGE", package),
                    },
                })
            end,
        },
    }
end

---@param state InstallerUiState
local function Installing(state)
    local packages = state.packages.installing
    return PackageListContainer {
        state = state,
        heading = Ui.HlTextNode(p.heading "Installing"),
        hide_when_empty = true,
        packages = packages,
        ---@param package Package
        list_item_renderer = function(package)
            ---@type UiPackageState
            local pkg_state = state.packages.states[package.name]
            local current_state = pkg_state.is_terminated and p.Comment " (cancelling)" or p.none ""
            return Ui.Node {
                Ui.HlTextNode {
                    {
                        p.highlight(settings.current.ui.icons.package_pending),
                        p.none(" " .. package.name),
                        current_state,
                        pkg_state.latest_spawn and p.Comment((" $ %s"):format(pkg_state.latest_spawn)) or p.none "",
                    },
                },
                Ui.Keybind(settings.current.ui.keymaps.cancel_installation, "TERMINATE_PACKAGE_HANDLE", package),
                Ui.CascadingStyleNode({ "INDENT" }, {
                    Ui.HlTextNode(_.map(function(line)
                        return { p.muted(line) }
                    end, pkg_state.tailed_output)),
                }),
            }
        end,
    }
end

---@param state InstallerUiState
local function Queued(state)
    local packages = state.packages.queued
    return PackageListContainer {
        state = state,
        heading = Ui.HlTextNode(p.heading "Queued"),
        packages = packages,
        hide_when_empty = true,
        ---@param package Package
        list_item_renderer = function(package)
            return Ui.Node {
                Ui.HlTextNode {
                    { p.highlight(settings.current.ui.icons.package_pending), p.none(" " .. package.name) },
                },
                Ui.Keybind(settings.current.ui.keymaps.cancel_installation, "DEQUEUE_PACKAGE", package),
            }
        end,
    }
end

---@param state InstallerUiState
local function Failed(state)
    local packages = state.packages.failed
    if #packages == 0 then
        return Ui.Node {}
    end
    return PackageListContainer {
        state = state,
        heading = Ui.HlTextNode(p.heading "Failed"),
        packages = packages,
        ---@param package Package
        list_item_renderer = function(package)
            return PackageComponent(state, package, {
                icon = p.error(settings.current.ui.icons.package_pending),
                keybinds = {
                    Ui.Keybind(settings.current.ui.keymaps.install_package, "INSTALL_PACKAGE", package),
                    Ui.Keybind(settings.current.ui.keymaps.toggle_package_expand, "TOGGLE_EXPAND_PACKAGE", package),
                },
            })
        end,
    }
end

---@param state InstallerUiState
local function Uninstalled(state)
    return PackageListContainer {
        state = state,
        heading = Ui.HlTextNode(p.heading "Available"),
        packages = state.packages.uninstalled,
        ---@param package Package
        list_item_renderer = function(package)
            return PackageComponent(state, package, {
                icon = p.muted(settings.current.ui.icons.package_uninstalled),
                keybinds = {
                    Ui.Keybind(settings.current.ui.keymaps.install_package, "INSTALL_PACKAGE", package),
                    Ui.Keybind(settings.current.ui.keymaps.toggle_package_expand, "TOGGLE_EXPAND_PACKAGE", package),
                },
            })
        end,
    }
end

---@param state InstallerUiState
return function(state)
    return Ui.CascadingStyleNode({ "INDENT" }, {
        Installed(state),
        Installing(state),
        Queued(state),
        Failed(state),
        Uninstalled(state),
    })
end
