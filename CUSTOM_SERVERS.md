# Custom servers

*Note that there may be breaking changes introduced over time that may have an impact on the functionality of custom
servers. These breaking changes should generally be easy to address.*

You may create your own server installers by using the same APIs that nvim-lsp-installer itself uses.

Each installable LSP server is represented as an instance of the `Server` class. This class is responsible for
containing all information required to both 1) install the server, and 2) set up the server through `lspconfig`. Refer
to the [Lua docs](./lua/nvim-lsp-installer/server.lua) for more details.

# Installers

Each `Server` instance must provide an `installer` property. This _must_ be a function with the signature `function (server, callback, context)`, where:

-   `server` is the server instance that is being installed,
-   `callback` is a function that _must_ be called upon completion (successful or not) by the installer implementation
-   `context` is a table containing contextual data, such as `stdio_sink` (see existing installer implementations for reference)

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

    #### `shell.bash(raw_script: string, opts?: table)`

    Returns an installer that runs the provided `raw_script` as a bash script.

    `opts` is an optional table, with the following defaults:

    -   `prefix: string` (default `"set -euo pipefail;"`) - Prefix added to the beginning of the script.
    -   `env = table?` (default `nil`) - A table (dict) with environment variables to be set in the shell.

    Example:

    ```lua
    local shell = require "nvim-lsp-installer.installers.shell"

    shell.bash [[
    wget -O server.zip https://github.com/fwcd/kotlin-language-server/releases/latest/download/server.zip;
    unzip server.zip;
    rm server.zip;
    ]]
    ```

    #### `shell.cmd(raw_script: string, opts?: table)`

    Returns an installer that runs the provided `raw_script` as a `cmd.exe` script.

    `opts` is an optional table, with the following defaults:

    -   `env = table?` (default `nil`) - A table (dict) with environment variables to be set in the shell.

    Example:

    ```lua
    local shell = require "nvim-lsp-installer.installers.shell"

    shell.cmd("git clone --depth 1 https://github.com/microsoft/vscode-eslint . && npm install && npm run compile:server")
    ```

    #### `shell.polyshell(raw_script: string, opts?: table)`

    Returns an installer that runs the provided `raw_script` as a platform agnostic shell script. This installer expects
    the provided `raw_script` is syntactically valid across all platform shells (`bash` and `cmd.exe`).

    `opts` is an optional table, with the following defaults:

    -   `env = table?` (default `nil`) - A table (dict) with environment variables to be set in the shell.

    Example:

    ```lua
    local shell = require "nvim-lsp-installer.installers.shell"

    shell.polyshell("git clone --depth 1 https://github.com/microsoft/vscode-eslint . && npm install && npm run compile:server")
    ```

-   ### std

    `std` is a collection of standard installers that provides cross-platform implementations for common tasks. Refer to
    the source code for more information.

## Composing installers

You may compose multiple different installers into one. This allows you to break down your installers into smaller
units.

Example:

```lua
local installers = require "nvim-lsp-installer.installers"
local shell = require "nvim-lsp-installer.installers.shell"
local std = require "nvim-lsp-installer.installers.std"

installers.pipe {
    std.download_file("Https://my.file/stuff.zip", "out.zip"),
    std.unzip("out.zip"),
    std.delete_file("out.zip"),
    npm.packages { "some-package" },
    pip3.packages { "another-package" },
    installers.on {
        unix = shell.bash [[ chmod +x something ]],
    },
}
```

## Full Example

The following is a full example of setting up a completely custom server installer, which in this example we call `my_server`.

```lua
local lspconfig = require "lspconfig"
local configs = require "lspconfig/configs"
local servers = require "nvim-lsp-installer.servers"
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

-- You may also use one of the prebuilt installers (e.g., std, npm, pip3, go, gem, shell).
local my_installer = function(server, callback, context)
    local is_success = code_that_installs_given_server(server)
    if is_success then
        callback(true)
    else
        callback(false)
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
servers.register(my_server)
```
