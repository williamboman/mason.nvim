# Custom servers

You may create your own server installers by using the same APIs that nvim-lsp-installer itself uses.

Each installable LSP server is represented as an instance of the `Server` class. This class is responsible for
containing all information required to both 1) install the server, and 2) set up the server through `lspconfig`. Refer
to the [Lua docs](./lua/nvim-lsp-installer/server.lua) for more details.

# Installers

Each `Server` instance must provide an `installer` property. This _must_ be a function with the signature `function (server, callback)`, where `server` is the server instance that is being installed, and `callback` is a function that
_must_ be called upon completion (successful or not) by the installer implementation.

## Core installers

Most likely, nvim-lsp-installer already have the installer implementations you need. Below are all the currently
available installers that are available out of the box.

-   ### Go

    #### `go.packages(packages: table)`

    Returns an installer that installs the provided list of `packages`.

    Example:

    ```lua
    local go = require "nvim-lsp-installer.installers.go"

    local installer = go.packages { "golang.org/x/tools/gopls@latest" }
    ```

    #### `go.executable(root_dir: string, executable: string)`

    Returns the absolute path to an `executable` that was installed via `go.packages()`. `root_dir` should be the same as
    the root_dir provided to the relevant server instance.

-   ### npm

    #### `npm.packages(packages: table)`

    Returns an installer that installs the provided list of `packages`.

    Example:

    ```lua
    local npm = require "nvim-lsp-installer.installers.npm"

    local installer = npm.packages { "graphql-language-service-cli", "graphql" }
    ```

    #### `npm.executable(root_dir: string, executable: string)`

    Returns the absolute path to an `executable` that was installed via `npm.packages()`. `root_dir` should be the same as
    the root_dir provided to the relevant server instance.

-   ### pip3

    #### `pip3.packages(packages: table)`

    Returns an installer that installs the provided list of `packages`.

    Example:

    ```lua
    local pip3 = require "nvim-lsp-installer.installers.pip3"

    local installer = pip3.packages { "python-lsp-server[all]" }
    ```

    #### `pip3.executable(root_dir: string, executable: string)`

    Returns the absolute path to an `executable` that was installed via `pip3.packages()`. `root_dir` should be the same as
    the root_dir provided to the relevant server instance.

-   ### Shell

    #### `shell.raw(raw_script: string, opts?: table)`

    Returns an installer that runs the provided `raw_script` in a new terminal window.

    Runs as a bash script (`/bin/bash`).

    `opts` is an optional table, with the following defaults:

    -   `prefix: string` (default `"set -euo pipefail;"`) - Prefix added to the beginning of the script.
    -   `env = table?` (default `nil`) - A table (dict) with environment variables to be set in the shell.

    Example:

    ```lua
    local shell = require "nvim-lsp-installer.installers.shell"

    shell.raw [[
    curl -fLO https://github.com/fwcd/kotlin-language-server/releases/latest/download/server.zip;
    unzip server.zip;
    rm server.zip;
    ]]
    ```

    #### `shell.remote(url: string, opts?: table)`

    Returns an installer that downloads the content at `url` and executes its content by passing it to the `shell.raw()`
    installer.

    `opts` is an optional table, with the following defaults:

    -   `prefix: string` (default `"set -euo pipefail;"`) - Prefix added to the beginning of the script.
    -   `env = table?` (default `nil`) - A table (dict) with environment variables to be set in the shell.

    Example:

    ```lua
    local shell = require "nvim-lsp-installer.installers.shell"

    shell.remote("https://raw.githubusercontent.com/my_server/my_server_lsp/install.sh", {
        env = {
            MY_ENV = "true"
        }
    })
    ```

-   ### zx

    [zx](https://github.com/google/zx) is a tool for writing better scripts. It's a suitable install method for servers
    that for example have many different steps or branches into different steps depending on some logic.

    #### `zx.file(relpath: string)`

    Returns an installer that executes the provided file as a `zx` script. `relpath` is the relative path (of the current
    Lua file) to the script file.

    Example:

    ```lua
    local zx = require "nvim-lsp-installer.installers.zx"

    local installer = zx.file("./install.mjs")
    ```

## Composing installers

You may compose multiple different installers into one. This allows you to break down your installers into smaller
units.

Example:

```lua
local installers = require "nvim-lsp-installer.installers"
local shell = require "nvim-lsp-installer.installers.shell"

installers.compose {
    shell.raw [[ echo "I won't run at all because the previous installer failed." ]],
    shell.raw [[ exit 1 ]],
    pip3.packages { "another-package" },
    npm.packages { "some-package" },
}
```

## Full Example

The following is a full example of setting up a completely custom server installer, which in this example we call `my_server`.

```lua
local lspconfig = require "lspconfig"
local configs = require "lspconfig/configs"
local lsp_installer = require "nvim-lsp-installer"
local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"

local server_name = "my_server"

-- 1. (optional, only if lspconfig doesn't already support the server)
--    Create server entry in lspconfig
configs[server_name] = {
    default_config = {
        filetypes = { "lua" },
        root_dir = lspconfig.util.root_pattern ".git",
    },
}

local root_dir = server.get_server_root_path(server_name)

-- You may also use one of the prebuilt installers (e.g., npm, pip3, go, shell, zx).
local my_installer = function(server, callback)
    local is_success = code_that_installs_given_server(server)
    if is_success then
        callback(true, nil)
    else
        callback(false, "Error message here.")
    end
end

-- 2. (mandatory) Create an nvim-lsp-installer Server instance
local my_server = server.Server:new {
    name = server_name,
    root_dir = root_dir,
    installer = my_installer,
    default_options = {
        cmd = { path.concat { root_dir, "my_server_lsp" }, "--langserver" },
    },
}

-- 3. (optional, recommended) Register your server with nvim-lsp-installer.
--    This makes it available via other APIs (e.g., :LspInstall, lsp_installer.get_available_servers()).
lsp_installer.register(my_server)
```
