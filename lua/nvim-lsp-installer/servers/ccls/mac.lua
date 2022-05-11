local path = require "nvim-lsp-installer.core.path"
local platform = require "nvim-lsp-installer.core.platform"
local installer = require "nvim-lsp-installer.core.installer"
local fs = require "nvim-lsp-installer.core.fs"

local ccls_installer = require "nvim-lsp-installer.servers.ccls.common"

---@async
return function()
    local ctx = installer.context()
    local homebrew_prefix = platform.get_homebrew_prefix():get_or_throw()
    local llvm_dir = path.concat { homebrew_prefix, "opt", "llvm", "lib", "cmake" }
    if not fs.async.dir_exists(llvm_dir) then
        ctx.stdio_sink.stderr(
            (
                "LLVM does not seem to be installed on this system (looked in %q). Please install LLVM via Homebrew:\n  $ brew install llvm\n"
            ):format(llvm_dir)
        )
        error "Unable to find LLVM."
    end
    ccls_installer { llvm_dir = llvm_dir }
end
