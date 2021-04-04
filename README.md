# nvim-lsp-installer

## About

Semi-opinionated companion plugin for [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig).
It comes with all batteries included, or at least to the extent possible. On top of just providing commands for
installing & uninsalling LSP servers, it:
- provides configurations for servers that aren't supported by nvim-lspconfig (`eslint`)
- provides extra APIs for non-standard LSP functionalities, for example `_typescript.applyRenameFile`

Inspired by [nvim-lspinstall](https://github.com/kabouzeid/nvim-lspinstall).

## Installation

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

- `:LspInstall <language>` - installs/reinstalls a language server
- `:LspUninstall <language>` - uninstalls a language server
- `:LspInstallAll` - installs all available language servers
- `:LspUninstallAll` - uninstalls all language servers
- `:LspPrintInstalled` - prints all installed language servers

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

    server.setup(opts)
end
```

## Extras

### tsserver

The `tsserver` language server comes with the following extras:

- `rename_file(old, new)` Tells the language server that a file was renamed. Useful when refactoring.

    Usage:
```lua
require'nvim-lsp-installer'.get_installer('tsserver').extras.rename_file(old, new)
```

- `organize_imports(bufname)` Organizes the imports of a file. `bufname` is optional, will default to current buffer.

    Usage:
```lua
require'nvim-lsp-installer'.get_installer('tsserver').extras.organize_imports(bufname)
```

## TODO

- installer... server... module.... pick one!!
- docs
- nicer API for accessing extras
