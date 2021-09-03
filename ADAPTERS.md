# Adapters (experimental)

The idea with the adapter API is to provide simple interfaces that allow for a richer LSP experience by combining the
functionalities of multiple plugins.

(make sure to only attempt connecting adapters once the plugin(s) involved have been loaded)

## [kyazdani42/nvim-tree.lua](https://github.com/kyazdani42/nvim-tree.lua)

```lua
require'nvim-lsp-installer.adapters.nvim-tree'.connect()
```

Supported capabilities:

-   `_typescript.applyRenameFile`. Automatically executes the rename file client request when renaming a node.
