local spy = require "luassert.spy"
local match = require "luassert.match"
local mock = require "luassert.mock"
local installer = require "nvim-lsp-installer.core.installer"
local Optional = require "nvim-lsp-installer.core.optional"
local gem = require "nvim-lsp-installer.core.managers.gem"
local Result = require "nvim-lsp-installer.core.result"
local spawn = require "nvim-lsp-installer.core.spawn"

describe("gem manager", function()
    ---@type InstallContext
    local ctx
    before_each(function()
        ctx = InstallContextGenerator {
            spawn = mock.new {
                gem = mockx.returns {},
            },
        }
    end)

    it(
        "should call gem install",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            installer.run_installer(ctx, gem.packages { "main-package", "supporting-package", "supporting-package2" })
            assert.spy(ctx.spawn.gem).was_called(1)
            assert.spy(ctx.spawn.gem).was_called_with(match.tbl_containing {
                "install",
                "--no-user-install",
                "--install-dir=.",
                "--bindir=bin",
                "--no-document",
                match.tbl_containing {
                    "main-package:42.13.37",
                    "supporting-package",
                    "supporting-package2",
                },
            })
        end)
    )

    it(
        "should provide receipt information",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            installer.run_installer(ctx, gem.packages { "main-package", "supporting-package", "supporting-package2" })
            assert.same({
                type = "gem",
                package = "main-package",
            }, ctx.receipt.primary_source)
            assert.same({
                {
                    type = "gem",
                    package = "supporting-package",
                },
                {
                    type = "gem",
                    package = "supporting-package2",
                },
            }, ctx.receipt.secondary_sources)
        end)
    )
end)

describe("gem version check", function()
    it(
        "should return current version",
        async_test(function()
            spawn.gem = spy.new(function()
                return Result.success {
                    stdout = [[shellwords (default: 0.1.0)
singleton (default: 0.1.1)
solargraph (0.44.0)
stringio (default: 3.0.1)
strscan (default: 3.0.1)
]],
                }
            end)

            local result = gem.get_installed_primary_package_version(
                mock.new {
                    primary_source = mock.new {
                        type = "gem",
                        package = "solargraph",
                    },
                },
                "/tmp/install/dir"
            )

            assert.spy(spawn.gem).was_called(1)
            assert.spy(spawn.gem).was_called_with(match.tbl_containing {
                "list",
                cwd = "/tmp/install/dir",
                env = match.tbl_containing {
                    GEM_HOME = "/tmp/install/dir",
                    GEM_PATH = "/tmp/install/dir",
                    PATH = match.matches "^/tmp/install/dir/bin:.*$",
                },
            })
            assert.is_true(result:is_success())
            assert.equals("0.44.0", result:get_or_nil())

            spawn.gem = nil
        end)
    )

    it(
        "should return outdated primary package",
        async_test(function()
            spawn.gem = spy.new(function()
                return Result.success {
                    stdout = [[bigdecimal (3.1.1 < 3.1.2)
cgi (0.3.1 < 0.3.2)
logger (1.5.0 < 1.5.1)
ostruct (0.5.2 < 0.5.3)
reline (0.3.0 < 0.3.1)
securerandom (0.1.1 < 0.2.0)
solargraph (0.44.0 < 0.44.3)
]],
                }
            end)

            local result = gem.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "gem",
                        package = "solargraph",
                    },
                },
                "/tmp/install/dir"
            )

            assert.spy(spawn.gem).was_called(1)
            assert.spy(spawn.gem).was_called_with(match.tbl_containing {
                "outdated",
                cwd = "/tmp/install/dir",
                env = match.tbl_containing {
                    GEM_HOME = "/tmp/install/dir",
                    GEM_PATH = "/tmp/install/dir",
                    PATH = match.matches "^/tmp/install/dir/bin:.*$",
                },
            })
            assert.is_true(result:is_success())
            assert.same({
                name = "solargraph",
                current_version = "0.44.0",
                latest_version = "0.44.3",
            }, result:get_or_nil())

            spawn.gem = nil
        end)
    )

    it(
        "should return failure if primary package is not outdated",
        async_test(function()
            spawn.gem = spy.new(function()
                return Result.success {
                    stdout = "",
                }
            end)

            local result = gem.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "gem",
                        package = "solargraph",
                    },
                },
                "/tmp/install/dir"
            )

            assert.is_true(result:is_failure())
            assert.equals("Primary package is not outdated.", result:err_or_nil())
            spawn.gem = nil
        end)
    )

    it("parses outdated gem output", function()
        local normalize = gem.parse_outdated_gem
        assert.same({
            name = "solargraph",
            current_version = "0.42.2",
            latest_version = "0.44.2",
        }, normalize [[solargraph (0.42.2 < 0.44.2)]])
        assert.same({
            name = "sorbet-runtime",
            current_version = "0.5.9307",
            latest_version = "0.5.9468",
        }, normalize [[sorbet-runtime (0.5.9307 < 0.5.9468)]])
    end)

    it("returns nil when unable to parse outdated gem", function()
        assert.is_nil(gem.parse_outdated_gem "a whole bunch of gibberish!")
        assert.is_nil(gem.parse_outdated_gem "")
    end)

    it("should parse gem list output", function()
        assert.same(
            {
                ["solargraph"] = "0.44.3",
                ["unicode-display_width"] = "2.1.0",
            },
            gem.parse_gem_list_output [[

*** LOCAL GEMS ***

nokogiri (1.13.3 arm64-darwin)
solargraph (0.44.3)
unicode-display_width (2.1.0)
]]
        )
    end)
end)
