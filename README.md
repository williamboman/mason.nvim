<p align="center">
  <img src="https://user-images.githubusercontent.com/6705160/118490159-f064bb00-b71d-11eb-883e-4affbd020074.png" alt="nvim-lsp-installer" width="60%" />
</p>

## About

Semi-opinionated companion plugin for [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig).
It comes with all batteries included, or at least to the extent possible. On top of just providing commands for
installing & uninsalling LSP servers, it:

-   provides configurations for servers that aren't supported by nvim-lspconfig (`eslint`)
-   provides extra APIs for non-standard LSP functionalities, for example `_typescript.applyRenameFile`
-   has support for a variety of different install methods (e.g., [google/zx](https://github.com/google/zx))
-   common install tasks are abstracted behind Lua APIs
-   provides adapters that offer out-of-box integrations with other plugins

Inspired by [nvim-lspinstall](https://github.com/kabouzeid/nvim-lspinstall).

## Installation

Some install scripts are written in [google/zx](https://github.com/google/zx) and will require a [Node.js LTS](https://nodejs.org/) runtime to be installed.

### vim-plug

```vim
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/nvim-lsp-installer'
```

### [Packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'neovim/nvim-lsp-config',
    'williamboman/nvim-lsp-installer',
}
```

## Usage

### Commands

-   `:LspInstall <language>` - installs/reinstalls a language server
-   `:LspUninstall <language>` - uninstalls a language server
-   `:LspUninstallAll` - uninstalls all language servers
-   `:LspPrintInstalled` - prints all installed language servers

### Setup

```lua
local lsp_installer = require'nvim-lsp-installer'

function common_on_attach(client, bufnr)
    -- setup buffer keymaps etc.
end

local installed_servers = lsp_installer.get_installed_servers()

for _, server in pairs(installed_servers) do
    opts = {
        on_attach = common_on_attach,
    }

    -- (optional) Customize the options passed to the server
    -- if server.name == "tsserver" then
    --     opts.root_dir = function() ... end
    -- end

    server:setup(opts)
end
```

For more advanced use cases you may also interact with more APIs nvim-lsp-installer has to offer, for example the following (refer to `:help nvim-lsp-installer` for more docs):

```lua
local lsp_installer = require'nvim-lsp-installer'

local ok, rust_analyzer = lsp_installer.get_server("rust_analyzer")
if ok then
    if not rust_analyzer:is_installed() then
        rust_analyzer:install()
    end
end
```

## Available LSPs

| Language                      | Server name              |
| ----------------------------- | ------------------------ |
| Angular                       | `angularls`              |
| Ansible                       | `ansiblels`              |
| Bash                          | `bashls`                 |
| C#                            | `omnisharp`              |
| C++                           | `clangd`                 |
| CMake                         | `cmake`                  |
| CSS                           | `cssls`                  |
| Clojure                       | `clojure_lsp`            |
| Deno                          | `denols`                 |
| Docker                        | `dockerls`               |
| EFM (general purpose server)  | `efm`                    |
| ESLint [(docs)][eslintls]     | `eslintls`               |
| Elixir                        | `elixirls`               |
| Elm                           | `elmls`                  |
| Ember                         | `ember`                  |
| Fortran                       | `fortls`                 |
| Go                            | `gopls`                  |
| GraphQL                       | `graphql`                |
| Groovy                        | `groovyls`               |
| HTML                          | `html`                   |
| Haskell                       | `hls`                    |
| JSON                          | `jsonls`                 |
| Jedi                          | `jedi_language_server`   |
| Kotlin                        | `kotlin_language_server` |
| LaTeX                         | `texlab`                 |
| Lua                           | `sumneko_lua`            |
| PHP                           | `intelephense`           |
| PureScript                    | `purescriptls`           |
| Python                        | `pylsp`                  |
| Python                        | `pyright`                |
| Rome                          | `rome`                   |
| Ruby                          | `solargraph`             |
| Rust                          | `rust_analyzer`          |
| SQL                           | `sqlls`                  |
| SQL                           | `sqls`                   |
| Svelte                        | `svelte`                 |
| Tailwind CSS                  | `tailwindcss`            |
| Terraform                     | `terraformls`            |
| Terraform [(docs)][tflint]    | `tflint`                 |
| TypeScript [(docs)][tsserver] | `tsserver`               |
| VimL                          | `vimls`                  |
| Vue                           | `vuels`                  |
| YAML                          | `yamlls`                 |

[eslintls]: ./lua/nvim-lsp-installer/servers/eslintls/README.md
[tflint]: ./lua/nvim-lsp-installer/servers/tflint/README.md
[tsserver]: ./lua/nvim-lsp-installer/servers/tsserver/README.md

## Adapters

Make sure to only attempt connecting adapters once the plugin(s) involved have been loaded.

### [kyazdani42/nvim-tree.lua](https://github.com/kyazdani42/nvim-tree.lua)

```lua
require'nvim-lsp-installer.adapters.nvim-tree'.connect()
```

Supported capabilities:

-   `_typescript.applyRenameFile`. Automatically executes the rename file client request when renaming a node.

## Logo

Illustrations in the logo are derived from [@Kaligule](https://schauderbasis.de/)'s "Robots" collection.

## Roadmap

-   Managed versioning of installed servers
-   Command (and corresponding Lua API) to update outdated servers (e.g., `:LspUpdate {server}`)
-   Cross-platform CI for all server installers
