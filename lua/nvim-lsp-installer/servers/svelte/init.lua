local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "svelte" },
        homepage = "https://github.com/sveltejs/language-tools",
        installer = npm.packages { "svelte-language-server" },
        default_options = {
            cmd = { npm.executable(root_dir, "svelteserver"), "--stdio" },
        },
    }
end
