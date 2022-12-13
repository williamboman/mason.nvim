local _ = require "mason-core.functional"

describe("functional: table", function()
    it("retrieves property of table", function()
        assert.equals("hello", _.prop("a", { a = "hello" }))
    end)

    it("retrieves nested property of table", function()
        assert.equals("hello", _.path({ "a", "greeting" }, { a = { greeting = "hello" } }))
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

    it("converts pairs to table", function()
        assert.same(
            { skies = "cloudy", temperature = "20°" },
            _.from_pairs {
                {
                    "skies",
                    "cloudy",
                },
                {
                    "temperature",
                    "20°",
                },
            }
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

    it("should evolve table", function()
        assert.same(
            {
                non_existent = nil,
                firstname = "JOHN",
                lastname = "DOE",
                age = 42,
            },
            _.evolve({
                non_existent = _.always "hello",
                firstname = _.to_upper,
                lastname = _.to_upper,
                age = _.add(2),
            }, {
                firstname = "John",
                lastname = "Doe",
                age = 40,
            })
        )
    end)

    it("should merge left", function()
        assert.same(
            {
                firstname = "John",
                lastname = "Doe",
            },
            _.merge_left({
                firstname = "John",
            }, {
                firstname = "Jane",
                lastname = "Doe",
            })
        )
    end)

    it("should dissoc keys", function()
        assert.same({
            a = "a",
            c = "c",
        }, _.dissoc("b", { a = "a", b = "b", c = "c" }))
    end)
end)
