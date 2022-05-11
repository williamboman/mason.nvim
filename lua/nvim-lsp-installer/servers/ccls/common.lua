local path = require "nvim-lsp-installer.core.path"
local platform = require "nvim-lsp-installer.core.platform"
local installer = require "nvim-lsp-installer.core.installer"
local git = require "nvim-lsp-installer.core.managers.git"
local Optional = require "nvim-lsp-installer.core.optional"

---@async
---@param opts {llvm_dir: string}
return function(opts)
    local ctx = installer.context()
    local clang_resource_dir = path.concat { ctx.destination_dir, "clang-resource" }
    local install_prefix = ctx.cwd:get()

    ctx.fs:mkdir "ccls-git"
    ctx:chdir("ccls-git", function()
        git.clone { "https://github.com/MaskRay/ccls", recursive = true }
        ctx.spawn.cmake {
            "-DCMAKE_BUILD_TYPE=Release",
            "-DUSE_SYSTEM_RAPIDJSON=OFF",
            "-DCMAKE_FIND_FRAMEWORK=LAST",
            "-Wno-dev",
            ("-DCMAKE_INSTALL_PREFIX=%s"):format(install_prefix),
            Optional.of_nilable(opts.llvm_dir)
                :map(function(llvm_dir)
                    return {
                        ("-DCMAKE_PREFIX_PATH=%s"):format(llvm_dir),
                        -- On Mac we use Homebrew LLVM which will persist after installation.
                        -- On Linux, and when a custom llvm_dir is provided, its clang resource dir will be the only
                        -- artifact persisted after installation, as the locally installed llvm installation will be
                        -- cleaned up after compilation.
                        not platform.is_mac and ("-DCLANG_RESOURCE_DIR=%s"):format(clang_resource_dir) or vim.NIL,
                    }
                end)
                :or_else(vim.NIL),
            platform.is_mac and "-DCMAKE_OSX_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk" or vim.NIL,
        }

        ctx.spawn.make { "install" }
    end)
    ctx.fs:rmrf "ccls-git"
end
