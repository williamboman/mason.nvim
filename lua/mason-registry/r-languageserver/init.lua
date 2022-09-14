local Pkg = require "mason-core.package"
local path = require "mason-core.path"
local github_client = require "mason-core.managers.github.client"
local github = require "mason-core.managers.github"

---@param install_dir string
---@param ref string
local function create_install_script(install_dir, ref)
    return ([[
options(langserver_library = %q);
options(langserver_quiet = FALSE);
options(repos = list(CRAN = "http://cran.rstudio.com/"));
rlsLib <- getOption("langserver_library");
.libPaths(new = rlsLib);

didInstallRemotes <- FALSE;
tryCatch(
  expr = { library("remotes") },
  error = function (e) {
    install.packages("remotes", lib = rlsLib);
    loadNamespace("remotes", lib.loc = rlsLib);
    didInstallRemotes <- TRUE;
  }
);

# We set force = TRUE because this command will error if languageserversetup is already installed (even if it's at a
# different library location).
remotes::install_github("jozefhajnala/languageserversetup", lib = rlsLib, force = TRUE);

if (didInstallRemotes) {
    remove.packages("remotes", lib = rlsLib);
}

loadNamespace("languageserversetup", lib.loc = rlsLib);
languageserversetup::languageserver_install(
    fullReinstall = FALSE,
    confirmBeforeInstall = FALSE,
    strictLibrary = TRUE,
    ref = %q
);
library("languageserver", lib.loc = rlsLib);
]]):format(install_dir, ref)
end

---@param install_dir string
local function create_server_script(install_dir)
    return ([[
options("langserver_library" = %q);
rlsLib <- getOption("langserver_library");
.libPaths(new = c(rlsLib, .libPaths()));
loadNamespace("languageserver", lib.loc = rlsLib);
languageserver::run();
  ]]):format(install_dir)
end

return Pkg.new {
    name = "r-languageserver",
    desc = [[An implementation of the Language Server Protocol for R]],
    homepage = "https://github.com/REditorSupport/languageserver",
    languages = { Pkg.Lang.R },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local source = github.release_version { repo = "REditorSupport/languageserver" }
        source.with_receipt()
        ctx.spawn.R {
            "--no-save",
            on_spawn = function(_, stdio)
                local stdin = stdio[1]
                stdin:write(create_install_script(ctx.cwd:get(), source.release))
                stdin:close()
            end,
        }
        ctx.fs:write_file("server.R", create_server_script(ctx.package:get_install_path()))

        ctx:link_bin(
            "r-languageserver",
            ctx:write_shell_exec_wrapper(
                "r-languageserver",
                ("R --slave -f %q"):format(path.concat { ctx.package:get_install_path(), "server.R" })
            )
        )
    end,
}
