<p align="center">
  <img src="https://user-images.githubusercontent.com/6705160/118490159-f064bb00-b71d-11eb-883e-4affbd020074.png" alt="nvim-lsp-installer" width="50%" />
</p>

-   [About](#about)
-   [Screenshots](#screenshots)
-   [Installation](#installation)
    -   [Packer](#packer)
    -   [vim-plug](#vim-plug)
-   [Usage](#usage)
    -   [Commands](#commands)
    -   [Setup](#setup)
    -   [Configuration](#configuration)
-   [Available LSPs](#available-lsps)
-   [Custom servers](#custom-servers)
-   [Logo](#logo)
-   [Roadmap](#roadmap)
-   [Default configuration](#default-configuration)

## About

Neovim plugin that allows you to seamlessly install LSP servers locally (inside `:echo stdpath("data")`).

On top of just providing commands for installing & uninstalling LSP servers, it:

-   provides a graphical UI
-   is optimized for blazing fast startup times
-   provides the ability to check for new server versions
-   supports installing custom versions of LSP servers (for example `:LspInstall rust_analyzer@nightly`)
-   relaxes the minimum requirements by attempting multiple different utilities (for example, only one of `wget`, `curl`, or `Invoke-WebRequest` is required for HTTP requests)
-   allows you to install and setup servers without having to restart neovim
-   hosts [a suite of system tests](https://github.com/williamboman/nvim-lspconfig-test) for all supported servers
-   has full support for Windows <img src="https://user-images.githubusercontent.com/6705160/131256603-cacf7f66-dfa9-4515-8ae4-0e42d08cfc6a.png" height="20">

## Screenshots

|                                                                                                                    |                                                                                                                    |                                                                                                                    |
| :----------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------------------: |
| <img src="https://user-images.githubusercontent.com/6705160/150685720-782e33ba-172c-44b6-8558-fb4e98495294.png" /> | <img src="https://user-images.githubusercontent.com/6705160/150685404-2cd34b25-166e-4c84-b9dd-1d5580dc2bdd.png" /> | <img src="https://user-images.githubusercontent.com/6705160/150685322-a537f021-5850-4bbc-8be2-1ece5678d205.png" /> |
| <img src="https://user-images.githubusercontent.com/6705160/150685324-1310ae7d-67bf-4053-872c-d27e8a4c4b80.png" /> | <img src="https://user-images.githubusercontent.com/6705160/150686052-fd5c4d54-b4da-4cb3-bb82-a094526ee5b5.png" /> | <img src="https://user-images.githubusercontent.com/6705160/150686059-f1be8131-1274-4f62-9aa8-345599cbd8bc.png" /> |

## Installation

Requires neovim `>= 0.6.0` and [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig). The _full requirements_ to
install _all_ servers are:

-   For Unix systems: git(1), curl(1) or wget(1), unzip(1), tar(1), gzip(1)
-   For Windows systems: powershell, git, tar, and [7zip][7zip] or [peazip][peazip] or [archiver][archiver] or [winzip][winzip] or [WinRAR][winrar]
-   Node.js (LTS) & npm
-   Python3 & pip3
-   go >= 1.17
-   JDK
-   Ruby & gem
-   PHP & Composer
-   dotnet
-   pwsh
-   Julia
-   valac (and meson & ninja)
-   rebar3

[7zip]: https://www.7-zip.org/
[archiver]: https://github.com/mholt/archiver
[peazip]: https://peazip.github.io/
[winzip]: https://www.winzip.com/
[winrar]: https://www.win-rar.com/

### [Packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'neovim/nvim-lspconfig',
    'williamboman/nvim-lsp-installer',
}
```

### vim-plug

```vim
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/nvim-lsp-installer'
```

## Usage

### Commands

-   `:LspInstallInfo` - opens a graphical overview of your language servers
-   `:LspInstall [--sync] [server] ...` - installs/reinstalls language servers. Runs in a blocking fashion if the `--sync` argument is passed (only recommended for scripting purposes).
-   `:LspUninstall [--sync] <server> ...` - uninstalls language servers. Runs in a blocking fashion if the `--sync` argument is passed (only recommended for scripting purposes).
-   `:LspUninstallAll [--no-confirm]` - uninstalls all language servers
-   `:LspInstallLog` - opens the log file in a new tab window
-   `:LspPrintInstalled` - prints all installed language servers

### Setup

The recommended way of setting up your installed servers is to do it through nvim-lsp-installer.
By doing so, nvim-lsp-installer will make sure to inject any necessary properties before calling lspconfig's setup
function for you. You may find a minimal example below. To see how you can override the default settings for a server,
refer to the [Wiki][overriding-default-settings].

Make sure you don't also set up your servers directly via lspconfig (e.g. `require("lspconfig").clangd.setup {}`), as
this will cause servers to be set up twice!

[overriding-default-settings]: https://github.com/williamboman/nvim-lsp-installer/wiki/Advanced-Configuration#overriding-the-default-lsp-server-options

```lua
local lsp_installer = require("nvim-lsp-installer")

-- Register a handler that will be called for each installed server when it's ready (i.e. when installation is finished
-- or if the server is already installed).
lsp_installer.on_server_ready(function(server)
    local opts = {}

    -- (optional) Customize the options passed to the server
    -- if server.name == "tsserver" then
    --     opts.root_dir = function() ... end
    -- end

    -- This setup() function will take the provided server configuration and decorate it with the necessary properties
    -- before passing it onwards to lspconfig.
    -- Refer to https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
    server:setup(opts)
end)
```

For more advanced use cases you may also interact with more APIs nvim-lsp-installer has to offer, refer to `:help nvim-lsp-installer` for more docs.

### Configuration

You can configure certain behavior of nvim-lsp-installer by calling the `.settings()` function.

_Make sure to provide your settings before any other interactions with nvim-lsp-installer!_

Refer to the [default configuration](#default-configuration) for all available settings.

Example:

```lua
local lsp_installer = require("nvim-lsp-installer")

lsp_installer.settings({
    ui = {
        icons = {
            server_installed = "✓",
            server_pending = "➜",
            server_uninstalled = "✗"
        }
    }
})
```

## Available LSPs

| Language                            | Server name                |
| ----------------------------------- | -------------------------- |
| AWK                                 | `awk_ls`                   |
| Angular                             | `angularls`                |
| Ansible                             | `ansiblels`                |
| Arduino [(docs!!!)][arduino]        | `arduino_language_server`  |
| Assembly (GAS/NASM, GO)             | `asm_lsp`                  |
| AsyncAPI                            | `spectral`                 |
| Bash                                | `bashls`                   |
| Beancount                           | `beancount`                |
| Bicep                               | `bicep`                    |
| C                                   | `ccls`                     |
| C                                   | `clangd`                   |
| C#                                  | `csharp_ls`                |
| C#                                  | `omnisharp`                |
| C++                                 | `ccls`                     |
| C++                                 | `clangd`                   |
| CMake                               | `cmake`                    |
| CSS                                 | `cssls`                    |
| CSS                                 | `cssmodules_ls`            |
| Clojure                             | `clojure_lsp`              |
| CodeQL                              | `codeqlls`                 |
| Crystal                             | `crystalline`              |
| Crystal                             | `scry`                     |
| Cucumber                            | `cucumber_language_server` |
| Dart                                | `dartls`                   |
| Deno                                | `denols`                   |
| Dhall                               | `dhall_lsp_server`         |
| Diagnostic (general purpose server) | `diagnosticls`             |
| Dlang                               | `serve_d`                  |
| Docker                              | `dockerls`                 |
| Dot                                 | `dotls`                    |
| EFM (general purpose server)        | `efm`                      |
| ESLint [(docs)][eslint]             | `eslint`                   |
| Elixir                              | `elixirls`                 |
| Elm                                 | `elmls`                    |
| Ember                               | `ember`                    |
| Emmet                               | `emmet_ls`                 |
| Erlang                              | `erlangls`                 |
| F#                                  | `fsautocomplete`           |
| Flux                                | `flux_lsp`                 |
| Foam (OpenFOAM)                     | `foam_ls`                  |
| Fortran                             | `fortls`                   |
| Go                                  | `golangci_lint_ls`         |
| Go                                  | `gopls`                    |
| Grammarly                           | `grammarly`                |
| GraphQL                             | `graphql`                  |
| Groovy                              | `groovyls`                 |
| HTML                                | `html`                     |
| Haskell                             | `hls`                      |
| Haxe                                | `haxe_language_server`     |
| JSON                                | `jsonls`                   |
| Java                                | `jdtls`                    |
| JavaScript                          | `quick_lint_js`            |
| JavaScript                          | `tsserver`                 |
| Jsonnet                             | `jsonnet_ls`               |
| Julia                               | `julials`                  |
| Kotlin                              | `kotlin_language_server`   |
| LaTeX                               | `ltex`                     |
| LaTeX                               | `texlab`                   |
| Lelwel                              | `lelwel_ls`                |
| Lua                                 | `sumneko_lua`              |
| Markdown                            | `remark_ls`                |
| Markdown                            | `zeta_note`                |
| Markdown                            | `zk`                       |
| Nickel                              | `nickel_ls`                |
| Nim                                 | `nimls`                    |
| OCaml                               | `ocamlls`                  |
| OCaml                               | `ocamllsp`                 |
| Objective C                         | `ccls`                     |
| OneScript, 1C:Enterprise            | `bsl_ls`                   |
| OpenAPI                             | `spectral`                 |
| OpenCL                              | `opencl_ls`                |
| Perl                                | `perlnavigator`            |
| PHP                                 | `intelephense`             |
| PHP                                 | `phpactor`                 |
| PHP                                 | `psalm`                    |
| Powershell                          | `powershell_es`            |
| Prisma                              | `prismals`                 |
| Puppet                              | `puppet`                   |
| PureScript                          | `purescriptls`             |
| Python                              | `jedi_language_server`     |
| Python                              | `pyright`                  |
| Python [(docs)][pylsp]              | `pylsp`                    |
| R                                   | `r_language_server`        |
| ReScript                            | `rescriptls`               |
| Reason                              | `reason_ls`                |
| Rome                                | `rome`                     |
| Ruby                                | `solargraph`               |
| Rust [(wiki)][rust_analyzer]        | `rust_analyzer`            |
| SQL                                 | `sqlls`                    |
| SQL                                 | `sqls`                     |
| Salt                                | `salt_ls`                  |
| Shopify Theme Check                 | `theme_check`              |
| Slint                               | `slint_lsp`                |
| Solidity                            | `solang`                   |
| Solidity                            | `solc`                     |
| Solidity (VSCode)                   | `solidity_ls`              |
| Sorbet                              | `sorbet`                   |
| Sphinx                              | `esbonio`                  |
| Stylelint                           | `stylelint_lsp`            |
| Svelte                              | `svelte`                   |
| Swift                               | `sourcekit`                |
| SystemVerilog                       | `svls`                     |
| SystemVerilog                       | `verible`                  |
| TOML                                | `taplo`                    |
| Tailwind CSS                        | `tailwindcss`              |
| Terraform                           | `terraformls`              |
| Terraform [(docs)][tflint]          | `tflint`                   |
| TypeScript [(docs)][tsserver]       | `tsserver`                 |
| Vala                                | `vala_ls`                  |
| VimL                                | `vimls`                    |
| Vue                                 | `volar`                    |
| Vue                                 | `vuels`                    |
| XML                                 | `lemminx`                  |
| YAML                                | `yamlls`                   |
| Zig                                 | `zls`                      |

[arduino]: ./lua/nvim-lsp-installer/servers/arduino_language_server/README.md
[eslint]: ./lua/nvim-lsp-installer/servers/eslint/README.md
[tflint]: ./lua/nvim-lsp-installer/servers/tflint/README.md
[tsserver]: ./lua/nvim-lsp-installer/servers/tsserver/README.md
[pylsp]: ./lua/nvim-lsp-installer/servers/pylsp/README.md
[rust_analyzer]: https://github.com/williamboman/nvim-lsp-installer/wiki/Rust

## Custom servers

You can create your own installers by using the same APIs nvim-lsp-installer itself uses. Refer to
[CUSTOM_SERVERS.md](./CUSTOM_SERVERS.md) for more information.

## Logo

Illustrations in the logo are derived from [@Kaligule](https://schauderbasis.de/)'s "Robots" collection.

## Roadmap

-   Command (and corresponding Lua API) to update outdated servers (e.g., `:LspUpdateAll`)

## Default configuration

```lua
local DEFAULT_SETTINGS = {
    ui = {
        icons = {
            -- The list icon to use for installed servers.
            server_installed = "◍",
            -- The list icon to use for servers that are pending installation.
            server_pending = "◍",
            -- The list icon to use for servers that are not installed.
            server_uninstalled = "◍",
        },
        keymaps = {
            -- Keymap to expand a server in the UI
            toggle_server_expand = "<CR>",
            -- Keymap to install a server
            install_server = "i",
            -- Keymap to reinstall/update a server
            update_server = "u",
            -- Keymap to update all installed servers
            update_all_servers = "U",
            -- Keymap to uninstall a server
            uninstall_server = "X",
        },
    },

    -- The directory in which to install all servers.
    install_root_dir = path.concat { vim.fn.stdpath "data", "lsp_servers" },

    pip = {
        -- These args will be added to `pip install` calls. Note that setting extra args might impact intended behavior
        -- and is not recommended.
        --
        -- Example: { "--proxy", "https://proxyserver" }
        install_args = {},
    },

    -- Controls to which degree logs are written to the log file. It's useful to set this to vim.log.levels.DEBUG when
    -- debugging issues with server installations.
    log_level = vim.log.levels.INFO,

    -- Limit for the maximum amount of servers to be installed at the same time. Once this limit is reached, any further
    -- servers that are requested to be installed will be put in a queue.
    max_concurrent_installers = 4,
}
```
