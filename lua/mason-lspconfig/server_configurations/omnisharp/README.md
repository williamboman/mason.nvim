# omnisharp

## How to enable Omnisharp Mono

By default, the `omnisharp` server will use the `dotnet` (NET6) runtime to run the server.
To run the server using the Mono runtime, set the `use_mono` setting like so:

```lua
local lspconfig = require("lspconfig")

lspconfig.omnisharp.setup {
    use_mono = true
}
```
