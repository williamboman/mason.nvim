local fs = require "nvim-lsp-installer.fs"
local lsp_installer = require "nvim-lsp-installer"

describe("fs", function()
    before_each(function()
        lsp_installer.settings {
            install_root_dir = "/foo",
        }
    end)

    it("refuses to rmrf unsafe paths", function()
        local e = assert.has.errors(function()
            fs.rmrf "/thisisa/path"
        end)

        assert.equal("Refusing to operate on path (/thisisa/path) outside of the servers root dir (/foo).", e)
    end)
end)
