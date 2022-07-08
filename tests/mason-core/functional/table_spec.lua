local _ = require "mason-core.functional"

describe("functional: table", function()
    it("retrieves property of table", function()
        assert.equals("hello", _.prop("a", { a = "hello" }))
    end)

    it("picks properties of table", function()
        local function fn() end
        assert.same(
            {
                ["key1"] = 1,
                [fn] = 2,
            },
            _.pick({ "key1", fn }, {
                ["key1"] = 1,
                [fn] = 2,
                [3] = 3,
            })
        )
    end)

    it("converts table to pairs", function()
        assert.same(
            _.sort_by(_.nth(1), {
                {
                    "skies",
                    "cloudy",
                },
                {
                    "temperature",
                    "20°",
                },
            }),
            _.sort_by(_.nth(1), _.to_pairs { skies = "cloudy", temperature = "20°" })
        )
    end)

    it("should invert tables", function()
        assert.same(
            {
                val1 = "key1",
                val2 = "key2",
            },
            _.invert {
                key1 = "val1",
                key2 = "val2",
            }
        )
    end)
end)
