# eslint

*NOTE*: You will have to install the [`eslint` package](https://www.npmjs.com/package/eslint) either locally or globally for the server to run successfully.

## Eslint in projects that use pnp

To allow the `eslint` server to resolve eslint and eslint plugins in a project that uses yarn 2/pnp, you need to manually change the
command used to run the server. This is done when setting up the LSP server, like so:

```lua
local eslint_config = require("lspconfig.server_configurations.eslint")
lspconfig.eslint.setup {
    opts.cmd = { "yarn", "exec", unpack(eslint_config.default_config.cmd) }
}
```
