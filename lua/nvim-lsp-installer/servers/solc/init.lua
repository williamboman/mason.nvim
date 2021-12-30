local server = require "nvim-lsp-installer.server"
local Data = require "nvim-lsp-installer.data"
local context = require "nvim-lsp-installer.installers.context"
local platform = require "nvim-lsp-installer.platform"
local std = require "nvim-lsp-installer.installers.std"
local path = require "nvim-lsp-installer.path"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    local bin_name = platform.is_win and "solc.exe" or "solc"

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/ethereum/solidity",
        languages = { "solidity" },
        installer = {
            context.capture(function(ctx)
                local file_template = coalesce(
                    when(platform.is_mac, "macosx-amd64/solc-macosx-amd64-%s"),
                    when(platform.is_linux and platform.arch == "x64", "linux-amd64/solc-linux-amd64-%s"),
                    when(platform.is_win and platform.arch == "x64", "windows-amd64/solc-windows-amd64-%s.exe")
                )
                if not file_template then
                    error(
                        ("Current operating system and/or arch (%q) is currently not supported."):format(platform.arch)
                    )
                end
                file_template = file_template:format(coalesce(ctx.requested_server_version, "latest"))
                return std.download_file(("https://binaries.soliditylang.org/%s"):format(file_template), bin_name)
            end),
            std.chmod("+x", { bin_name }),
        },
        default_options = {
            cmd = { path.concat { root_dir, bin_name }, "--lsp" },
        },
    }
end
