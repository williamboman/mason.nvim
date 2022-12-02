[![GitHub CI](https://github.com/williamboman/mason.nvim/workflows/Tests/badge.svg)](https://github.com/williamboman/mason.nvim/actions?query=workflow%3ATests+branch%3Amain+event%3Apush)
![Platforms](https://img.shields.io/badge/platform-linux%20macOS%20windows-blue)
![Repository size](https://img.shields.io/github/repo-size/williamboman/mason.nvim)
[![Sponsors](https://img.shields.io/github/sponsors/williamboman?style=flat-square)](https://github.com/sponsors/williamboman)

<img src="https://user-images.githubusercontent.com/6705160/177613416-0c0354d2-f431-40d8-87f0-21310f0bba0e.png" alt="mason.nvim" />

<p align="center">
    Portable package manager for Neovim that runs everywhere Neovim runs.<br />
    Easily install and manage LSP servers, DAP servers, linters, and formatters.<br />
    <code>:help mason.nvim</code>
</p>

# Table of Contents

-   [Introduction](#introduction)
    -   [How to use installed packages](#how-to-use-installed-packages)
-   [Screenshots](#screenshots)
-   [Requirements](#requirements)
-   [Installation](#installation)
-   [Setup](#setup)
    -   [Extensions](#extensions)
-   [Commands](#commands)
-   [Configuration](#configuration)

# Introduction

> `:h mason-introduction`

`mason.nvim` is a Neovim plugin that allows you to easily manage external editor tooling such as LSP servers, DAP servers,
linters, and formatters through a single interface. It runs everywhere Neovim runs (across Linux, macOS, Windows, etc.),
with only a small set of [external requirements](#requirements) needed.

Packages are installed in Neovim's `:h stdpath` by default. Executables are linked to a single `bin/` directory, which
`mason.nvim` will add to Neovim's PATH during setup, allowing seamless access from Neovim builtins (shell, terminal,
etc.) as well as other 3rd party plugins.

For a list of all available packages, see [PACKAGES.md](./PACKAGES.md).

## How to use installed packages

> `:h mason-how-to-use-packages`

Although many packages are perfectly usable out of the box through Neovim builtins, it is recommended to use other 3rd
party plugins to further integrate these. The following plugins are recommended:

-   LSP: [`lspconfig`][lspconfig] & [`mason-lspconfig.nvim`][mason-lspconfig.nvim]
-   DAP: [`nvim-dap`][nvim-dap]
-   Linters: [`null-ls.nvim`][null-ls.nvim] or [`nvim-lint`][nvim-lint]
-   Formatters: [`null-ls.nvim`][null-ls.nvim] or [`formatter.nvim`][formatter.nvim]

[formatter.nvim]: https://github.com/mhartington/formatter.nvim
[lspconfig]: https://github.com/neovim/nvim-lspconfig
[mason-lspconfig.nvim]: https://github.com/williamboman/mason-lspconfig.nvim
[null-ls.nvim]: https://github.com/jose-elias-alvarez/null-ls.nvim
[nvim-dap]: https://github.com/mfussenegger/nvim-dap
[nvim-lint]: https://github.com/mfussenegger/nvim-lint

## Screenshots

|                                                                                                                                                        |                                                                                                                                                  |                                                                                                                                        |
| :----------------------------------------------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------------------------------------------------------: |
|           <img alt="Main window" src="https://user-images.githubusercontent.com/6705160/177617680-d62caf26-f253-4ace-ab57-4b590595adca.png">           |                 <img src="https://user-images.githubusercontent.com/6705160/177617684-6bb4c13f-1235-4ac9-829e-120b06f7437b.png">                 | <img alt="Language filter" src="https://user-images.githubusercontent.com/6705160/177617688-8f9ba225-00c8-495c-9c4c-b74240d6f280.png"> |
| <img alt="LSP server configuration schema" src="https://user-images.githubusercontent.com/6705160/177617692-02c6ddde-a97e-42b4-bca4-4f4caf45d569.png"> | <img alt="Checking for new versions" src="https://user-images.githubusercontent.com/6705160/180648183-69077d10-8795-4da6-ba4d-57ecf0cb25c9.png"> |   <img alt="Help window" src="https://user-images.githubusercontent.com/6705160/180648292-136a0888-0fb6-4226-aa29-53bd3ffed400.png">   |

# Requirements

> `:h mason-requirements`

`mason.nvim` relaxes the minimum requirements by attempting multiple different utilities (for example, `wget`,
`curl`, and `Invoke-WebRequest` are all perfect substitutes).
The _minimum_ recommended requirements are:

-   neovim `>= 0.7.0`
-   For Unix systems: `git(1)`, `curl(1)` or `wget(1)`, `unzip(1)`, `tar(1)`, `gzip(1)`
-   For Windows systems: pwsh, git, tar, and [7zip][7zip] or [peazip][peazip] or [archiver][archiver] or [winzip][winzip] or [WinRAR][winrar]

Note that `mason.nvim` will regularly shell out to external package managers, such as `cargo` and `npm`. Depending on
your personal usage, some of these will also need to be installed. Refer to `:checkhealth mason` for a full list.

[7zip]: https://www.7-zip.org/
[archiver]: https://github.com/mholt/archiver
[peazip]: https://peazip.github.io/
[winzip]: https://www.winzip.com/
[winrar]: https://www.win-rar.com/

# Installation

## [Packer](https://github.com/wbthomason/packer.nvim)

```lua
use { "williamboman/mason.nvim" }
```

## vim-plug

```vim
Plug 'williamboman/mason.nvim'
```

# Setup

> `:h mason-quickstart`

```lua
require("mason").setup()
```

`mason.nvim` is optimized to load as little as possible during setup. Lazy-loading the plugin, or somehow deferring the
setup, is not recommended.

Refer to the [Configuration](#configuration) section for information about which settings are available.

## Extensions

Refer to the [Wiki](https://github.com/williamboman/mason.nvim/wiki/Extensions) for a list of 3rd party extensions.

-   [`mason-lspconfig.nvim`](https://github.com/williamboman/mason-lspconfig.nvim) - recommended for usage with `lspconfig`

# Commands

> `:h mason-commands`

-   `:Mason` - opens a graphical status window
-   `:MasonInstall <package> ...` - installs/reinstalls the provided packages
-   `:MasonUninstall <package> ...` - uninstalls the provided packages
-   `:MasonUninstallAll` - uninstalls all packages
-   `:MasonLog` - opens the `mason.nvim` log file in a new tab window

# Configuration

> `:h mason-settings`

You may optionally configure certain behavior of `mason.nvim` when calling the `.setup()` function. Refer to the
[default configuration](#default-configuration) for a list of all available settings.

Example:

```lua
require("mason").setup({
    ui = {
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
        }
    }
})
```

## Default configuration

```lua
local DEFAULT_SETTINGS = {
    -- The directory in which to install packages.
    install_root_dir = path.concat { vim.fn.stdpath "data", "mason" },

    -- Where Mason should put its bin location in your PATH. Can be one of:
    -- - "prepend" (default, Mason's bin location is put first in PATH)
    -- - "append" (Mason's bin location is put at the end of PATH)
    -- - "skip" (doesn't modify PATH)
    ---@type '"prepend"' | '"append"' | '"skip"'
    PATH = "prepend",

    pip = {
        -- Whether to upgrade pip to the latest version in the virtual environment before installing packages.
        upgrade_pip = false,

        -- These args will be added to `pip install` calls. Note that setting extra args might impact intended behavior
        -- and is not recommended.
        --
        -- Example: { "--proxy", "https://proxyserver" }
        install_args = {},
    },

    -- Controls to which degree logs are written to the log file. It's useful to set this to vim.log.levels.DEBUG when
    -- debugging issues with package installations.
    log_level = vim.log.levels.INFO,

    -- Limit for the maximum amount of packages to be installed at the same time. Once this limit is reached, any further
    -- packages that are requested to be installed will be put in a queue.
    max_concurrent_installers = 4,

    github = {
        -- The template URL to use when downloading assets from GitHub.
        -- The placeholders are the following (in order):
        -- 1. The repository (e.g. "rust-lang/rust-analyzer")
        -- 2. The release version (e.g. "v0.3.0")
        -- 3. The asset name (e.g. "rust-analyzer-v0.3.0-x86_64-unknown-linux-gnu.tar.gz")
        download_url_template = "https://github.com/%s/releases/download/%s/%s",
    },

    -- The provider implementations to use for resolving package metadata (latest version, available versions, etc.).
    -- Accepts multiple entries, where later entries will be used as fallback should prior providers fail.
    -- Builtin providers are:
    --   - mason.providers.registry-api (default) - uses the https://api.mason-registry.dev API
    --   - mason.providers.client                 - uses only client-side tooling to resolve metadata
    providers = {
        "mason.providers.registry-api",
    },

    ui = {
        -- Whether to automatically check for new versions when opening the :Mason window.
        check_outdated_packages_on_open = true,

        -- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
        border = "none",

        icons = {
            -- The list icon to use for installed packages.
            package_installed = "◍",
            -- The list icon to use for packages that are installing, or queued for installation.
            package_pending = "◍",
            -- The list icon to use for packages that are not installed.
            package_uninstalled = "◍",
        },

        keymaps = {
            -- Keymap to expand a package
            toggle_package_expand = "<CR>",
            -- Keymap to install the package under the current cursor position
            install_package = "i",
            -- Keymap to reinstall/update the package under the current cursor position
            update_package = "u",
            -- Keymap to check for new version for the package under the current cursor position
            check_package_version = "c",
            -- Keymap to update all installed packages
            update_all_packages = "U",
            -- Keymap to check which installed packages are outdated
            check_outdated_packages = "C",
            -- Keymap to uninstall a package
            uninstall_package = "X",
            -- Keymap to cancel a package installation
            cancel_installation = "<C-c>",
            -- Keymap to apply language filter
            apply_language_filter = "<C-f>",
        },
    },
}
```

---

<sup>
👋 didn't find what you were looking for? Try looking in the <a href="./doc/mason.txt">help docs</a> <code>:help mason.nvim</code>!
</sup>
