local on_windows = vim.loop.os_uname().version:match "Windows"

local function join_paths(...)
    local path_sep = on_windows and "\\" or "/"
    local result = table.concat({ ... }, path_sep)
    return result
end

vim.opt.runtimepath = vim.env.VIMRUNTIME
vim.opt.completeopt = "menu"

local temp_dir = vim.loop.os_getenv "TEMP" or "/tmp"

vim.opt.packpath = join_paths(temp_dir, "nvim-lsp-installer-debug", "site")

local package_root = join_paths(temp_dir, "nvim-lsp-installer-debug", "site", "pack")
local install_path = join_paths(package_root, "packer", "start", "packer.nvim")
local compile_path = join_paths(install_path, "plugin", "packer_compiled.lua")

local function load_plugins()
    require("packer").startup {
        {
            "wbthomason/packer.nvim",
            "neovim/nvim-lspconfig",
            "williamboman/nvim-lsp-installer",
        },
        config = {
            package_root = package_root,
            compile_path = compile_path,
        },
    }
end

function _G.load_config()
    local lspconfig = require "lspconfig"

    local function on_attach(client, bufnr)
        vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
    end

    require("nvim-lsp-installer").setup {
        log = vim.log.levels.DEBUG,
    }

    -- ==================================================
    -- ========= SETUP RELEVANT SERVER(S) HERE! =========
    -- ==================================================
    --
    -- lspconfig.sumneko_lua.setup { on_attach = on_attach }
end

if vim.fn.isdirectory(install_path) == 0 then
    vim.fn.system { "git", "clone", "https://github.com/wbthomason/packer.nvim", install_path }
    load_plugins()
    require("packer").sync()
    vim.cmd [[autocmd User PackerComplete ++once lua load_config()]]
else
    load_plugins()
    require("packer").sync()
    _G.load_config()
end
