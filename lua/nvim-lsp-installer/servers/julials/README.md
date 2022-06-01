# julials

## Configuring the Julia Environment

The Julia Environment will be identified in the following order:

1) user configuration (`lspconfig.julials.setup { julia_env_path = "/my/env" }`)
2) if the `Project.toml` & `Manifest.toml` (or `JuliaProject.toml` & `JuliaManifest.toml`) files exists in the current project working directory, the current project working directory is used as the environment
3) the result of `Pkg.Types.Context().env.project_file`
