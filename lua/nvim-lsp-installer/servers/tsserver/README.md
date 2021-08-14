# tsserver

The `tsserver` language server comes with the following extras:

-   `rename_file(old, new)` Tells the language server that a file was renamed. Useful when refactoring. Refer to the [adapters section](/README.md#adapters) to find plugin integrations that automatically executes this for you.

    Usage:

```lua
require'nvim-lsp-installer.extras.tsserver'.rename_file(old, new)
```

-   `organize_imports(bufname)` Organizes the imports of a file. `bufname` is optional, will default to current buffer.

    Usage:

```lua
require'nvim-lsp-installer.extras.tsserver'.organize_imports(bufname)
```
