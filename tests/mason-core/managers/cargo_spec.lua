local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local cargo = require "mason-core.managers.cargo"
local cargo_client = require "mason-core.managers.cargo.client"
local github = require "mason-core.managers.github"
local github_client = require "mason-core.managers.github.client"
local installer = require "mason-core.installer"
local match = require "luassert.match"
local mock = require "luassert.mock"
local path = require "mason-core.path"
local spawn = require "mason-core.spawn"
local spy = require "luassert.spy"
local stub = require "luassert.stub"

describe("cargo manager", function()
    it(
        "should call cargo install",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "42.13.37" })
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, cargo.crate "my-crate")
            assert.spy(ctx.spawn.cargo).was_called(1)
            assert.spy(ctx.spawn.cargo).was_called_with {
                "install",
                "--root",
                ".",
                "--locked",
                { "--version", "42.13.37" },
                vim.NIL, -- --git
                vim.NIL, -- --features
                "my-crate",
            }
        end)
    )

    it(
        "should call cargo install with git source",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, cargo.crate("my-crate", { git = { url = "https://my-crate.git" } }))
            assert.spy(ctx.spawn.cargo).was_called(1)
            assert.spy(ctx.spawn.cargo).was_called_with {
                "install",
                "--root",
                ".",
                "--locked",
                vim.NIL, -- version
                { "--git", "https://my-crate.git" },
                vim.NIL, -- --features
                "my-crate",
            }
        end)
    )

    it(
        "should call cargo install with git source and a specific crate",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, cargo.crate("crate-name", { git = { url = "https://my-crate.git" } }))
            assert.spy(ctx.spawn.cargo).was_called(1)
            assert.spy(ctx.spawn.cargo).was_called_with {
                "install",
                "--root",
                ".",
                "--locked",
                vim.NIL, -- version
                { "--git", "https://my-crate.git" },
                vim.NIL, -- --features
                "crate-name",
            }
        end)
    )

    it(
        "should respect options",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "42.13.37" })
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, cargo.crate("my-crate", { features = "lsp" }))
            assert.spy(ctx.spawn.cargo).was_called(1)
            assert.spy(ctx.spawn.cargo).was_called_with {
                "install",
                "--root",
                ".",
                "--locked",
                { "--version", "42.13.37" },
                vim.NIL, -- --git
                { "--features", "lsp" },
                "my-crate",
            }
        end)
    )

    it(
        "should target tagged git crates",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            stub(github, "tag")
            github.tag.returns { tag = "v2.1.1", with_receipt = mockx.just_runs }
            local ctx = InstallContextGenerator(handle, { version = "42.13.37" })
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(
                ctx,
                cargo.crate("my-crate", {
                    git = {
                        url = "https://github.com/crate/my-crate",
                        tag = true,
                    },
                    features = "lsp",
                })
            )
            assert.spy(ctx.spawn.cargo).was_called_with {
                "install",
                "--root",
                ".",
                "--locked",
                { "--tag", "v2.1.1" },
                { "--git", "https://github.com/crate/my-crate" }, -- --git
                { "--features", "lsp" },
                "my-crate",
            }
        end)
    )

    it(
        "should provide receipt information",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, cargo.crate "main-package")
            assert.same({
                type = "cargo",
                package = "main-package",
            }, ctx.receipt.primary_source)
        end)
    )
end)

describe("cargo version check", function()
    it("parses cargo installed packages output", function()
        assert.same(
            {
                ["bat"] = { name = "bat", version = "0.18.3" },
                ["exa"] = { name = "exa", version = "0.10.1" },
                ["git-select-branch"] = { name = "git-select-branch", version = "0.1.1" },
                ["hello_world"] = { name = "hello_world", version = "0.0.1" },
                ["rust-analyzer"] = {
                    name = "rust-analyzer",
                    version = "187bee0b",
                    github_ref = { owner = "rust-lang", repo = "rust-analyzer", ref = "187bee0b" },
                },
                ["move-analyzer"] = {
                    name = "move-analyzer",
                    version = "3cef7fa8",
                    github_ref = { owner = "move-language", repo = "move", ref = "3cef7fa8" },
                },
                ["stylua"] = { name = "stylua", version = "0.11.2" },
                ["zoxide"] = { name = "zoxide", version = "0.5.0" },
            },
            cargo.parse_installed_crates(_.dedent [[
                bat v0.18.3:
                    bat
                exa v0.10.1:
                    exa
                git-select-branch v0.1.1:
                    git-select-branch
                hello_world v0.0.1 (/private/var/folders/ky/s6yyhm_d24d0jsrql4t8k4p40000gn/T/tmp.LGbguATJHj):
                    hello_world
                move-analyzer v1.0.0 (https://github.com/move-language/move#3cef7fa8):
                    move-analyzer
                rust-analyzer v0.0.0 (https://github.com/rust-lang/rust-analyzer?tag=2022-09-19#187bee0b):
                    rust-analyzer
                stylua v0.11.2:
                    stylua
                zoxide v0.5.0:
                    zoxide
            ]])
        )
    end)

    it(
        "should return current version",
        async_test(function()
            stub(spawn, "cargo")
            spawn.cargo.returns(Result.success {
                stdout = _.dedent [[
                    flux-lsp v0.8.8 (https://github.com/influxdata/flux-lsp#4e452f07):
                    flux-lsp
                ]],
            })

            local result = cargo.get_installed_primary_package_version(
                mock.new {
                    primary_source = mock.new {
                        type = "cargo",
                        package = "https://github.com/influxdata/flux-lsp",
                    },
                },
                path.package_prefix "dummy"
            )

            assert.spy(spawn.cargo).was_called(1)
            assert.spy(spawn.cargo).was_called_with(match.tbl_containing {
                "install",
                "--list",
                "--root",
                ".",
                cwd = path.package_prefix "dummy",
            })
            assert.is_true(result:is_success())
            assert.equals("4e452f07", result:get_or_nil())
        end)
    )

    it(
        "should return outdated primary package",
        async_test(function()
            stub(spawn, "cargo")
            spawn.cargo.returns(Result.success {
                stdout = _.dedent [[
                    lelwel v0.4.0:
                    lelwel-ls
                ]],
            })
            stub(cargo_client, "fetch_crate")
            cargo_client.fetch_crate.returns(Result.success {
                crate = {
                    id = "lelwel",
                    max_stable_version = "0.4.2",
                    max_version = "0.4.2",
                    newest_version = "0.4.2",
                },
            })

            local result = cargo.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "cargo",
                        package = "lelwel",
                    },
                },
                path.package_prefix "dummy"
            )

            assert.spy(spawn.cargo).was_called(1)
            assert.spy(spawn.cargo).was_called_with(match.tbl_containing {
                "install",
                "--list",
                "--root",
                ".",
                cwd = path.package_prefix "dummy",
            })
            assert.is_true(result:is_success())
            assert.is_true(match.tbl_containing {
                current_version = "0.4.0",
                latest_version = "0.4.2",
                name = "lelwel",
            }(result:get_or_nil()))
        end)
    )

    it(
        "should recognize up-to-date crates",
        async_test(function()
            stub(spawn, "cargo")
            spawn.cargo.returns(Result.success {
                stdout = _.dedent [[
                    lelwel v0.4.0:
                    lelwel-ls
                ]],
            })
            stub(cargo_client, "fetch_crate")
            cargo_client.fetch_crate.returns(Result.success {
                crate = {
                    id = "lelwel",
                    max_stable_version = "0.4.0",
                    max_version = "0.4.0",
                    newest_version = "0.4.0",
                },
            })

            local result = cargo.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "cargo",
                        package = "lelwel",
                    },
                },
                path.package_prefix "dummy"
            )

            assert.is_true(result:is_failure())
            assert.equals("Primary package is not outdated.", result:err_or_nil())
        end)
    )

    it(
        "should return outdated primary package from git source",
        async_test(function()
            stub(spawn, "cargo")
            spawn.cargo.returns(Result.success {
                stdout = _.dedent [[
                    move-analyzer v1.0.0 (https://github.com/move-language/move#3cef7fa8):
                    move-analyzer
                ]],
            })

            stub(github_client, "fetch_commits")
            github_client.fetch_commits
                .on_call_with("move-language/move", { page = 1, per_page = 1 })
                .returns(Result.success {
                    {
                        sha = "b243f1fb",
                    },
                })

            local result = cargo.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "cargo",
                        package = "move-analyzer",
                    },
                },
                path.package_prefix "dummy"
            )

            assert.spy(spawn.cargo).was_called(1)
            assert.spy(spawn.cargo).was_called_with(match.tbl_containing {
                "install",
                "--list",
                "--root",
                ".",
                cwd = path.package_prefix "dummy",
            })
            assert.is_true(result:is_success())
            assert.is_true(match.tbl_containing {
                current_version = "3cef7fa8",
                latest_version = "b243f1fb",
                name = "move-analyzer",
            }(result:get_or_nil()))
        end)
    )
end)
