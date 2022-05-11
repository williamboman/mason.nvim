local fs = require "nvim-lsp-installer.core.fs"
local lsp_installer = require "nvim-lsp-installer"

describe("fs", function()
    before_each(function()
        lsp_installer.settings {
            install_root_dir = "/foo",
        }
    end)

    it(
        "refuses to rmrf paths outside of boundary",
        async_test(function()
            local e = assert.has.errors(function()
                fs.async.rmrf "/thisisa/path"
            end)

            assert.equal(
                [[Refusing to rmrf "/thisisa/path" which is outside of the allowed boundary "/foo". Please report this error at https://github.com/williamboman/nvim-lsp-installer/issues/new]],
                e
            )
        end)
    )
end)
