local Ui = require "mason-core.ui"
local _ = require "mason-core.functional"
local p = require "mason.ui.palette"
local settings = require "mason.settings"

---@param state InstallerUiState
return function(state)
    local uninstalled_registries = _.filter(_.prop_eq("is_installed", false), state.info.registries)

    return Ui.Node {
        Ui.CascadingStyleNode({ "CENTERED" }, {
            Ui.HlTextNode {
                Ui.When(state.view.is_showing_help, {
                    p.header_secondary(" " .. state.header.title_prefix .. " mason.nvim "),
                    p.none((" "):rep(#state.header.title_prefix + 1)),
                }, {
                    p.header " mason.nvim ",
                    state.view.is_searching and p.Comment " (search mode, press <Esc> to clear)" or p.none "",
                }),
                Ui.When(state.view.is_showing_help, {
                    p.none "        press ",
                    p.highlight_secondary(settings.current.ui.keymaps.toggle_help),
                    p.none " for package list",
                }, {
                    p.none "press ",
                    p.highlight(settings.current.ui.keymaps.toggle_help),
                    p.none " for help",
                }),
                { p.Comment "https://github.com/williamboman/mason.nvim" },
            },
        }),
        Ui.When(not state.packages.new_versions_check.is_checking and #uninstalled_registries > 0, function()
            return Ui.CascadingStyleNode({ "INDENT" }, {
                Ui.EmptyLine(),
                Ui.HlTextNode {
                    {
                        p.warning "Uninstalled registries",
                    },
                    {
                        p.Comment "Packages from the following registries are unavailable. Press ",
                        p.highlight(settings.current.ui.keymaps.check_outdated_packages),
                        p.Comment " to install.",
                    },
                    unpack(_.map(function(registry)
                        return { p.none(" - " .. registry.name) }
                    end, uninstalled_registries)),
                },
                Ui.EmptyLine(),
            })
        end),
        Ui.When(
            not state.packages.new_versions_check.is_checking and state.info.registry_update_error,
            Ui.CascadingStyleNode({ "INDENT" }, {
                Ui.HlTextNode {
                    {
                        p.error "Registry installation failed with the following error:",
                    },
                    {
                        p.none "  ",
                        p.Comment(state.info.registry_update_error),
                    },
                },
                Ui.EmptyLine(),
            })
        ),
    }
end
