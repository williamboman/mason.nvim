local path = require "nvim-lsp-installer.core.path"
local platform = require "nvim-lsp-installer.core.platform"
local installer = require "nvim-lsp-installer.core.installer"
local github = require "nvim-lsp-installer.core.managers.github"
local functional = require "nvim-lsp-installer.core.functional"
local Result = require "nvim-lsp-installer.core.result"
local Optional = require "nvim-lsp-installer.core.optional"

local ccls_installer = require "nvim-lsp-installer.servers.ccls.common"

local coalesce, when = functional.coalesce, functional.when

---@param release string
local function normalize_llvm_release(release)
    -- Strip the "llvmorg-" prefix from tags (llvm releases tags like llvmorg-13.0.0)
    local normalized_release = release:gsub("^llvmorg%-", "")
    return normalized_release
end

---@async
local function llvm_installer()
    local ctx = installer.context()
    local os_dist = platform.os_distribution()

    local asset_name = coalesce(
        when(
            platform.arch == "x64",
            coalesce(
                when(
                    os_dist.id == "ubuntu" and os_dist.version.major >= 20,
                    "clang+llvm-%s-x86_64-linux-gnu-ubuntu-20.04"
                ),
                when(
                    os_dist.id == "ubuntu" and os_dist.version.major >= 16,
                    "clang+llvm-%s-x86_64-linux-gnu-ubuntu-16.04"
                )
            )
        ),
        when(platform.arch == "arm64", "clang+llvm-%s-aarch64-linux-gnu"),
        when(platform.arch == "armv7", "clang+llvm-%s-armv7a-linux-gnueabihf")
    )

    local source = github.untarxz_release_file {
        repo = "llvm/llvm-project",
        version = Optional.of "llvmorg-13.0.0",
        asset_file = function(release)
            local normalized_release = normalize_llvm_release(release)
            return asset_name and ("%s.tar.xz"):format(asset_name):format(normalized_release)
        end,
    }

    ctx.fs:rename(asset_name:format(normalize_llvm_release(source.release)), "llvm")
    -- We move the clang headers out, because they need to be persisted
    ctx.fs:rename(path.concat { "llvm", "lib", "clang", normalize_llvm_release(source.release) }, "clang-resource")

    return path.concat { ctx.cwd:get(), "llvm" }
end

---@async
return function()
    local ctx = installer.context()
    Result.run_catching(llvm_installer)
        :map(function(llvm_dir)
            ccls_installer { llvm_dir = llvm_dir }
            ctx.fs:rmrf "llvm"
        end)
        :recover(function()
            pcall(function()
                ctx.fs:rmrf "llvm"
            end)
            ccls_installer {}
        end)
end
