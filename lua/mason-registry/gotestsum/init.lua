local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "gotestsum",
    desc = _.dedent [[
      'go test' runner with output optimized for humans, JUnit XML for CI integration, and 
      a summary of the test results.
    ]],
    homepage = "https://github.com/gotestyourself/gotestsum",
    categories = {},
    languages = { Pkg.Lang.Go },
    install = go.packages { "gotest.tools/gotestsum", bin = { "gotestsum" } },
}
