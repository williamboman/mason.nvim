local Ui = require "mason.core.ui"
local p = require "mason.ui.palette"

local PackageList = require "mason.ui.components.main.package_list"

---@param state InstallerUiState
return function(state)
    return Ui.Node {
        Ui.EmptyLine(),
        PackageList(state),
    }
end
