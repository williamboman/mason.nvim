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

    it("should assoc keys", function()
        assert.same({
            a = "a",
            b = "b",
            c = "c",
        }, _.assoc("b", "b", { a = "a", c = "c" }))
    end)
end)

describe("table immutability", function()
    it("should not mutate tables", function()
        local og_table = setmetatable({ key = "value", imagination = "poor", hotel = "trivago" }, {
            __newindex = function()
                error "Tried to newindex"
            end,
        })

        _.prop("hotel", og_table)
        _.path({ "hotel" }, og_table)
        _.pick({ "hotel" }, og_table)
        _.keys(og_table)
        _.size(og_table)
        _.from_pairs(_.to_pairs(og_table))
        _.invert(og_table)
        _.evolve({ hotel = _.to_upper }, og_table)
        _.merge_left(og_table, {})
        _.assoc("new", "value", og_table)
        _.dissoc("hotel", og_table)

        assert.same({ key = "value", imagination = "poor", hotel = "trivago" }, og_table)
    end)
end)
