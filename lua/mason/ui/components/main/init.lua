local Ui = require "mason-core.ui"

local PackageList = require "mason.ui.components.main.package_list"

---@param state InstallerUiState
return function(state)
    return Ui.Node {
        Ui.EmptyLine(),
        PackageList(state),
    }
end
