local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "protolint",
    desc = [[protolint is the pluggable linting/fixing utility for Protocol Buffer files (proto2+proto3)]],
    homepage = "https://github.com/yoheimuta/protolint",
    categories = { Pkg.Cat.Linter },
    languages = { Pkg.Lang.Protobuf },
    install = function(ctx)
        ---@param template_string string
        local function release_file(template_string)
            return _.compose(_.format(template_string), _.gsub("^v", ""))
        end

        github
            .untargz_release_file({
                repo = "yoheimuta/protolint",
                asset_file = coalesce(
                    when(platform.is.mac_arm64, release_file "protolint_%s_Darwin_arm64.tar.gz"),
                    when(platform.is.mac_x64, release_file "protolint_%s_Darwin_x86_64.tar.gz"),
                    when(platform.is.linux_arm64, release_file "protolint_%s_Linux_arm64.tar.gz"),
                    when(platform.is.linux_x64, release_file "protolint_%s_Linux_x86_64.tar.gz"),
                    when(platform.is.win_arm64, release_file "protolint_%s_Windows_arm64.tar.gz"),
                    when(platform.is.win_x64, release_file "protolint_%s_Windows_x86_64.tar.gz")
                ),
            })
            .with_receipt()
        ctx:link_bin("protolint", platform.is.win and "protolint.exe" or "protolint")
        ctx:link_bin("protoc-gen-protolint", platform.is.win and "protoc-gen-protolint.exe" or "protoc-gen-protolint")
    end,
}
