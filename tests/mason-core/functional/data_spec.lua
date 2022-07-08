local _ = require "mason-core.functional"

describe("functional: data", function()
    it("creates enums", function()
        local colors = _.enum {
            "BLUE",
            "YELLOW",
        }
        assert.same({
            ["BLUE"] = "BLUE",
            ["YELLOW"] = "YELLOW",
        }, colors)
    end)

    it("creates sets", function()
        local colors = _.set_of {
            "BLUE",
            "YELLOW",
            "BLUE",
            "RED",
        }
        assert.same({
            ["BLUE"] = true,
            ["YELLOW"] = true,
            ["RED"] = true,
        }, colors)
    end)
end)
