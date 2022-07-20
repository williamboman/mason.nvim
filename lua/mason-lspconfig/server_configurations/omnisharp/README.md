# omnisharp

## How to enable Omnisharp Mono

By default, the `omnisharp` server will use the `dotnet` (NET6) runtime to run the server.
To run the server using the Mono runtime, set the `use_modern_net` setting to `false`, like so:

__This requires the `omnisharp-mono` package to be installed.__

```lua
local lspconfig = require("lspconfig")

lspconfig.omnisharp.setup {
    use_modern_net = false
}
```
