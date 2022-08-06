local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"
local path = require "mason-core.path"

return Pkg.new {
    name = "debugpy",
    desc = [[An implementation of the Debug Adapter Protocol for Python]],
    homepage = "https://github.com/microsoft/debugpy",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.DAP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        pip3.install({ "debugpy" }).with_receipt()
        ctx:link_bin("debugpy", ctx:write_pyvenv_exec_wrapper("debugpy", "debugpy"))
        ctx:link_bin("debugpy-adapter", ctx:write_pyvenv_exec_wrapper("debugpy-adapter", "debugpy.adapter"))
    end,
}
