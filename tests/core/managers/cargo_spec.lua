local spy = require "luassert.spy"
local match = require "luassert.match"
local mock = require "luassert.mock"
local Optional = require "nvim-lsp-installer.core.optional"
local installer = require "nvim-lsp-installer.core.installer"
local cargo = require "nvim-lsp-installer.core.managers.cargo"
local Result = require "nvim-lsp-installer.core.result"
local spawn = require "nvim-lsp-installer.core.spawn"

describe("cargo manager", function()
    ---@type InstallContext
    local ctx
    before_each(function()
        ctx = InstallContextGenerator {
            spawn = mock.new {
                cargo = mockx.returns {},
            },
        }
    end)

    it(
        "should call cargo install",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            installer.run_installer(ctx, cargo.crate "my-crate")
            assert.spy(ctx.spawn.cargo).was_called(1)
            assert.spy(ctx.spawn.cargo).was_called_with {
                "install",
                "--root",
                ".",
                "--locked",
                { "--version", "42.13.37" },
                vim.NIL, -- --features
                "my-crate",
            }
        end)
    )

    it(
        "should call cargo install with git source",
        async_test(function()
            installer.run_installer(ctx, cargo.crate("https://my-crate.git", { git = true }))
            assert.spy(ctx.spawn.cargo).was_called(1)
            assert.spy(ctx.spawn.cargo).was_called_with {
                "install",
                "--root",
                ".",
                "--locked",
                vim.NIL,
                vim.NIL, -- --features
                { "--git", "https://my-crate.git" },
            }
        end)
    )

    it(
        "should call cargo install with git source and a specific crate",
        async_test(function()
            installer.run_installer(ctx, cargo.crate("crate-name", { git = "https://my-crate.git" }))
            assert.spy(ctx.spawn.cargo).was_called(1)
            assert.spy(ctx.spawn.cargo).was_called_with {
                "install",
                "--root",
                ".",
                "--locked",
                vim.NIL,
                vim.NIL, -- --features
                { "--git", "https://my-crate.git", "crate-name" },
            }
        end)
    )

    it(
        "should respect options",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            installer.run_installer(ctx, cargo.crate("my-crate", { features = "lsp" }))
            assert.spy(ctx.spawn.cargo).was_called(1)
            assert.spy(ctx.spawn.cargo).was_called_with {
                "install",
                "--root",
                ".",
                "--locked",
                { "--version", "42.13.37" },
                { "--features", "lsp" },
                "my-crate",
            }
        end)
    )

    it(
        "should not allow combining version with git crate",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            local err = assert.has_error(function()
                installer.run_installer(
                    ctx,
                    cargo.crate("my-crate", {
                        git = true,
                    })
                )
            end)
            assert.equals("Providing a version when installing a git crate is not allowed.", err)
            assert.spy(ctx.spawn.cargo).was_called(0)
        end)
    )

    it(
        "should provide receipt information",
        async_test(function()
            installer.run_installer(ctx, cargo.crate "main-package")
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
                ["bat"] = "0.18.3",
                ["exa"] = "0.10.1",
                ["git-select-branch"] = "0.1.1",
                ["hello_world"] = "0.0.1",
                ["rust-analyzer"] = "0.0.0",
                ["stylua"] = "0.11.2",
                ["zoxide"] = "0.5.0",
            },
            cargo.parse_installed_crates [[bat v0.18.3:
    bat
exa v0.10.1:
    exa
git-select-branch v0.1.1:
    git-select-branch
hello_world v0.0.1 (/private/var/folders/ky/s6yyhm_d24d0jsrql4t8k4p40000gn/T/tmp.LGbguATJHj):
    hello_world
rust-analyzer v0.0.0 (/private/var/folders/ky/s6yyhm_d24d0jsrql4t8k4p40000gn/T/tmp.YlsHeA9JVL/crates/rust-analyzer):
    rust-analyzer
stylua v0.11.2:
    stylua
zoxide v0.5.0:
    zoxide
]]
        )
    end)

    it(
        "should return current version",
        async_test(function()
            spawn.cargo = spy.new(function()
                return Result.success {
                    stdout = [[flux-lsp v0.8.8 (https://github.com/influxdata/flux-lsp#4e452f07):
    flux-lsp
]],
                }
            end)

            local result = cargo.get_installed_primary_package_version(
                mock.new {
                    primary_source = mock.new {
                        type = "cargo",
                        package = "https://github.com/influxdata/flux-lsp",
                    },
                },
                "/tmp/install/dir"
            )

            assert.spy(spawn.cargo).was_called(1)
            assert.spy(spawn.cargo).was_called_with(match.tbl_containing {
                "install",
                "--list",
                "--root",
                ".",
                cwd = "/tmp/install/dir",
            })
            assert.is_true(result:is_success())
            assert.equals("0.8.8", result:get_or_nil())

            spawn.cargo = nil
        end)
    )

    -- XXX: This test will actually send http request to crates.io's API. It's not mocked.
    it(
        "should return outdated primary package",
        async_test(function()
            spawn.cargo = spy.new(function()
                return Result.success {
                    stdout = [[lelwel v0.4.0:
    lelwel-ls
]],
                }
            end)

            local result = cargo.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "cargo",
                        package = "lelwel",
                    },
                },
                "/tmp/install/dir"
            )

            assert.spy(spawn.cargo).was_called(1)
            assert.spy(spawn.cargo).was_called_with(match.tbl_containing {
                "install",
                "--list",
                "--root",
                ".",
                cwd = "/tmp/install/dir",
            })
            assert.is_true(result:is_success())
            assert.is_true(match.tbl_containing {
                current_version = "0.4.0",
                latest_version = match.matches "%d.%d.%d",
                name = "lelwel",
            }(result:get_or_nil()))

            spawn.cargo = nil
        end)
    )
end)
