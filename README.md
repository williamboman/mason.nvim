![repo size](https://img.shields.io/github/repo-size/williamboman/nvim-lsp-installer?style=flat-square)
![checks status](https://img.shields.io/github/checks-status/williamboman/nvim-lsp-installer/main?style=flat-square)

<p align="center">
  <img src="https://user-images.githubusercontent.com/6705160/118490159-f064bb00-b71d-11eb-883e-4affbd020074.png" alt="nvim-lsp-installer" width="60%" />
</p>

<img src="https://user-images.githubusercontent.com/6705160/138860384-ec041595-2c23-43b7-a5a7-979b0efb3daf.gif" />

## About

Companion plugin for [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) that allows you to seamlessly install
LSP servers locally (inside `:echo stdpath("data")`).

On top of just providing commands for installing & uninstalling LSP servers, it:

-   provides a graphical UI
-   optimized for blazing fast startup times
-   supports installing custom versions of LSP servers (for example `:LspInstall rust_analyzer@nightly`)
-   common install tasks are abstracted behind composable Lua APIs (has direct integration with libuv via vim.loop)
-   minimum requirements are relaxed by attempting multiple different utilities (for example, only one of `wget`, `curl`, or `Invoke-WebRequest` is required for HTTP requests)
-   <img src="https://user-images.githubusercontent.com/6705160/131256603-cacf7f66-dfa9-4515-8ae4-0e42d08cfc6a.png" height="20"> full support for Windows

## Installation

Requires neovim `>= 0.5.0` and [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig). The full requirements to
install all servers are:

-   For Unix systems: bash(1), git(1), curl(1) or wget(1), unzip(1), tar(1), gzip(1)
-   For Windows systems: powershell, git, tar, and [7zip][7zip] or [peazip][peazip] or [archiver][archiver] or [winzip][winzip]
-   Node.js (LTS) & npm
-   Python3 & pip3
-   go
-   javac
-   Ruby & gem

[7zip]: https://www.7-zip.org/
[archiver]: https://github.com/mholt/archiver
[peazip]: https://peazip.github.io/
[winzip]: https://www.winzip.com/

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
-   `:LspInstall [--sync] <server> ...` - installs/reinstalls language servers. Runs in a blocking fashion if the `--sync` argument is passed (only recommended for scripting purposes).
-   `:LspUninstall [--sync] <server> ...` - uninstalls language servers. Runs in a blocking fashion if the `--sync` argument is passed (only recommended for scripting purposes).
-   `:LspUninstallAll [--no-confirm]` - uninstalls all language servers
-   `:LspInstallLog` - opens the log file in a new tab window
-   `:LspPrintInstalled` - prints all installed language servers

### Setup

```lua
local lsp_installer = require("nvim-lsp-installer")

-- Register a handler that will be called for all installed servers.
-- Alternatively, you may also register handlers on specific server instances instead (see example below).
lsp_installer.on_server_ready(function(server)
    local opts = {}

    -- (optional) Customize the options passed to the server
    -- if server.name == "tsserver" then
    --     opts.root_dir = function() ... end
    -- end

    -- This setup() function is exactly the same as lspconfig's setup function.
    -- Refer to https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
    server:setup(opts)
end)
```

For more advanced use cases you may also interact with more APIs nvim-lsp-installer has to offer, for example the following (refer to `:help nvim-lsp-installer` for more docs).

```lua
local lsp_installer_servers = require'nvim-lsp-installer.servers'

local server_available, requested_server = lsp_installer_servers.get_server("rust_analyzer")
if server_available then
    requested_server:on_ready(function ()
        local opts = {}
        requested_server:setup(opts)
    end)
    if not requested_server:is_installed() then
        -- Queue the server to be installed
        requested_server:install()
    end
end
```

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

| Language                            | Server name              |
| ----------------------------------- | ------------------------ |
| Angular                             | `angularls`              |
| Ansible                             | `ansiblels`              |
| Bash                                | `bashls`                 |
| Bicep                               | `bicep`                  |
| C#                                  | `omnisharp`              |
| C++                                 | `clangd`                 |
| CMake                               | `cmake`                  |
| CSS                                 | `cssls`                  |
| Clojure                             | `clojure_lsp`            |
| CodeQL                              | `codeqlls`               |
| Dart                                | `dartls`                 |
| Deno                                | `denols`                 |
| Diagnostic (general purpose server) | `diagnosticls`           |
| Dlang                               | `serve_d`                |
| Docker                              | `dockerls`               |
| Dot                                 | `dotls`                  |
| EFM (general purpose server)        | `efm`                    |
| ESLint [(docs)][eslint]             | `eslint`                 |
| Elixir                              | `elixirls`               |
| Elm                                 | `elmls`                  |
| Ember                               | `ember`                  |
| Emmet                               | `emmet_ls`               |
| Erlang                              | `erlangls`               |
| F#                                  | `fsautocomplete`         |
| Fortran                             | `fortls`                 |
| Go                                  | `gopls`                  |
| GraphQL                             | `graphql`                |
| Groovy                              | `groovyls`               |
| HTML                                | `html`                   |
| Haskell                             | `hls`                    |
| JSON                                | `jsonls`                 |
| Java                                | `jdtls`                  |
| Jsonnet                             | `jsonnet_ls`             |
| Kotlin                              | `kotlin_language_server` |
| LaTeX                               | `ltex`                   |
| LaTeX                               | `texlab`                 |
| Lua                                 | `sumneko_lua`            |
| OCaml                               | `ocamlls`                |
| PHP                                 | `intelephense`           |
| PHP                                 | `phpactor`               |
| Powershell                          | `powershell_es`          |
| Prisma                              | `prismals`               |
| Puppet                              | `puppet`                 |
| PureScript                          | `purescriptls`           |
| Python                              | `jedi_language_server`   |
| Python                              | `pylsp`                  |
| Python                              | `pyright`                |
| ReScript                            | `rescriptls`             |
| Rome                                | `rome`                   |
| Ruby                                | `solargraph`             |
| Rust                                | `rust_analyzer`          |
| SQL                                 | `sqlls`                  |
| SQL                                 | `sqls`                   |
| Solang Solidity                     | `solang`                 |
| Sorbet                              | `sorbet`                 |
| Sphinx                              | `esbonio`                |
| Stylelint                           | `stylelint_lsp`          |
| Svelte                              | `svelte`                 |
| Tailwind CSS                        | `tailwindcss`            |
| Terraform                           | `terraformls`            |
| Terraform [(docs)][tflint]          | `tflint`                 |
| TypeScript [(docs)][tsserver]       | `tsserver`               |
| Vala                                | `vala_ls`                |
| VimL                                | `vimls`                  |
| Vue                                 | `volar`                  |
| Vue                                 | `vuels`                  |
| XML                                 | `lemminx`                |
| YAML                                | `yamlls`                 |
| Zig                                 | `zls`                    |

[eslint]: ./lua/nvim-lsp-installer/servers/eslint/README.md
[tflint]: ./lua/nvim-lsp-installer/servers/tflint/README.md
[tsserver]: ./lua/nvim-lsp-installer/servers/tsserver/README.md

## Custom servers

You can create your own installers by using the same APIs nvim-lsp-installer itself uses. Refer to
[CUSTOM_SERVERS.md](./CUSTOM_SERVERS.md) for more information.

## Logo

Illustrations in the logo are derived from [@Kaligule](https://schauderbasis.de/)'s "Robots" collection.

## Roadmap

-   Command (and corresponding Lua API) to update outdated servers (e.g., `:LspUpdate {server}`)
-   More helpful metadata displayed in the UI window
-   Cross-platform CI for all server installers

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
