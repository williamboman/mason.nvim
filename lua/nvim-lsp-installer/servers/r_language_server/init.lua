local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.process"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    local function create_install_script(install_dir)
        return ([[
options(langserver_library = %q);
options(repos = list(CRAN = "http://cran.rstudio.com/"));
rlsLib <- getOption("langserver_library");
install.packages("languageserversetup", lib = rlsLib);
loadNamespace("languageserversetup", lib.loc = rlsLib);

languageserversetup::languageserver_install(
    fullReinstall = TRUE,
    confirmBeforeInstall = FALSE,
    strictLibrary = TRUE
);
]]):format(install_dir, install_dir, install_dir)
    end

    local server_script = ([[
options("langserver_library" = %q);
rlsLib <- getOption("langserver_library");
.libPaths(new = rlsLib);
loadNamespace("languageserver", lib.loc = rlsLib);
languageserver::run();
  ]]):format(root_dir)

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/REditorSupport/languageserver",
        languages = { "R" },
        installer = {
            function(_, callback, ctx)
                process.spawn("R", {
                    cwd = ctx.install_dir,
                    args = { "-e", create_install_script(ctx.install_dir) },
                    stdio_sink = ctx.stdio_sink,
                }, callback)
            end,
            context.receipt(function(receipt)
                receipt:with_primary_source(receipt.r_package "languageserver")
            end),
        },
        default_options = {
            cmd = { "R", "--slave", "-e", server_script },
        },
    }
end
