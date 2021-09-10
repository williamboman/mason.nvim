<p align="center">
  <img src="https://user-images.githubusercontent.com/6705160/118490159-f064bb00-b71d-11eb-883e-4affbd020074.png" alt="nvim-lsp-installer" width="60%" />
</p>

<p align="center">
  <a href="https://asciinema.org/a/434365" target="_blank" rel="noopener">
    <img src="https://user-images.githubusercontent.com/6705160/132266914-e0f89b07-35e2-45ff-a55e-560f612f8a45.gif" width="650" />
  </a>
</p>

## About

Companion plugin for [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) that allows you to seamlessly install
LSP servers locally (inside `:echo stdpath("data")`).

On top of just providing commands for installing & uninstalling LSP servers, it:

-   provides a graphical UI
-   provides configurations for servers that aren't supported by nvim-lspconfig (`eslint`)
-   common install tasks are abstracted behind Lua APIs (has direct integration with libuv via vim.loop)
-   <img src="https://user-images.githubusercontent.com/6705160/131256603-cacf7f66-dfa9-4515-8ae4-0e42d08cfc6a.png" height="20"> full support for Windows

## Installation

Requires neovim `>= 0.5.0`. These are the full requirements to install all servers:

-   neovim/nvim-lspconfig (https://github.com/neovim/nvim-lspconfig)
-   For Unix systems: bash(1), git(1), wget(1), unzip(1), tar(1), gzip(1)
-   For Windows systems: powershell.exe, tar, git
-   Node.js (LTS) & npm
-   Python3 & pip3
-   go
-   javac
-   Ruby & gem

### [Packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'neovim/nvim-lsp-config',
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
-   `:LspInstall <server> ...` - installs/reinstalls language servers
-   `:LspUninstall <server> ...` - uninstalls language servers
-   `:LspUninstallAll` - uninstalls all language servers
-   `:LspPrintInstalled` - prints all installed language servers

### Setup

```lua
local lsp_installer = require("nvim-lsp-installer")

lsp_installer.on_server_ready(function(server)
    local opts = {}

    -- (optional) Customize the options passed to the server
    -- if server.name == "tsserver" then
    --     opts.root_dir = function() ... end
    -- end

    -- This setup() function is exactly the same as lspconfig's setup function (:help lspconfig-quickstart)
    server:setup(opts)
    vim.cmd [[ do User LspAttachBuffers ]]
end)
```

For more advanced use cases you may also interact with more APIs nvim-lsp-installer has to offer, for example the following (refer to `:help nvim-lsp-installer` for more docs):

```lua
local lsp_installer_servers = require'nvim-lsp-installer.servers'

local ok, rust_analyzer = lsp_installer_servers.get_server("rust_analyzer")
if ok then
    if not rust_analyzer:is_installed() then
        rust_analyzer:install()
    end
end
```

## Available LSPs

| Language                            | Server name              |
| ----------------------------------- | ------------------------ |
| Angular                             | `angularls`              |
| Ansible                             | `ansiblels`              |
| Bash                                | `bashls`                 |
| C#                                  | `omnisharp`              |
| C++                                 | `clangd`                 |
| CMake                               | `cmake`                  |
| CSS                                 | `cssls`                  |
| Clojure                             | `clojure_lsp`            |
| Deno                                | `denols`                 |
| Diagnostic (general purpose server) | `diagnosticls`           |
| Docker                              | `dockerls`               |
| EFM (general purpose server)        | `efm`                    |
| ESLint [(docs)][eslintls]           | `eslintls`               |
| Elixir                              | `elixirls`               |
| Elm                                 | `elmls`                  |
| Ember                               | `ember`                  |
| Fortran                             | `fortls`                 |
| Go                                  | `gopls`                  |
| GraphQL                             | `graphql`                |
| Groovy                              | `groovyls`               |
| HTML                                | `html`                   |
| Haskell                             | `hls`                    |
| JSON                                | `jsonls`                 |
| Jedi                                | `jedi_language_server`   |
| Kotlin                              | `kotlin_language_server` |
| LaTeX                               | `texlab`                 |
| Lua                                 | `sumneko_lua`            |
| PHP                                 | `intelephense`           |
| Prisma                              | `prismals`               |
| PureScript                          | `purescriptls`           |
| Python                              | `pylsp`                  |
| Python                              | `pyright`                |
| ReScript                            | `rescriptls`             |
| Rome                                | `rome`                   |
| Ruby                                | `solargraph`             |
| Rust                                | `rust_analyzer`          |
| SQL                                 | `sqlls`                  |
| SQL                                 | `sqls`                   |
| Stylelint                           | `stylelint_lsp`          |
| Svelte                              | `svelte`                 |
| Tailwind CSS                        | `tailwindcss`            |
| Terraform                           | `terraformls`            |
| Terraform [(docs)][tflint]          | `tflint`                 |
| TypeScript [(docs)][tsserver]       | `tsserver`               |
| VimL                                | `vimls`                  |
| Vue                                 | `vuels`                  |
| YAML                                | `yamlls`                 |

[eslintls]: ./lua/nvim-lsp-installer/servers/eslintls/README.md
[tflint]: ./lua/nvim-lsp-installer/servers/tflint/README.md
[tsserver]: ./lua/nvim-lsp-installer/servers/tsserver/README.md

## Custom servers

You can create your own installers by using the same APIs nvim-lsp-installer itself uses. Refer to
[CUSTOM_SERVERS.md](./CUSTOM_SERVERS.md) for more information.

## Logo

Illustrations in the logo are derived from [@Kaligule](https://schauderbasis.de/)'s "Robots" collection.

## Roadmap

-   Managed versioning of installed servers
-   Command (and corresponding Lua API) to update outdated servers (e.g., `:LspUpdate {server}`)
-   Cross-platform CI for all server installers
