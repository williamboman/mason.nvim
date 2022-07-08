local Ui = require "mason-core.ui"
local p = require "mason.ui.palette"

---@param state InstallerUiState
return function(state)
    if not state.stats.used_disk_space then
        return Ui.Node {}
    end
    return Ui.CascadingStyleNode({ "CENTERED" }, {
        Ui.Table {
            {
                p.muted "Used disk space:",
                p.none(state.stats.used_disk_space),
            },
        },
    })
end
