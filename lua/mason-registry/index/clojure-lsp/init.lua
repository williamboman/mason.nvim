local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "clojure-lsp",
    desc = [[A Language Server for Clojure(script). Taking a Cursive-like approach of statically analyzing code.]],
    homepage = "https://clojure-lsp.io",
    languages = { Pkg.Lang.Clojure, Pkg.Lang.ClojureScript },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        github
            .unzip_release_file({
                repo = "clojure-lsp/clojure-lsp",
                asset_file = coalesce(
                    when(platform.is.mac_arm64, "clojure-lsp-native-macos-aarch64.zip"),
                    when(platform.is.mac_x64, "clojure-lsp-native-macos-amd64.zip"),
                    when(platform.is.linux_x64_musl, "clojure-lsp-native-static-linux-amd64.zip"),
                    when(platform.is.linux_x64_gnu, "clojure-lsp-native-linux-amd64.zip"),
                    when(platform.is.linux_arm64, "clojure-lsp-native-linux-aarch64.zip"),
                    when(platform.is.win_x64, "clojure-lsp-native-windows-amd64.zip")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "clojure-lsp" })
        ctx:link_bin("clojure-lsp", platform.is.win and "clojure-lsp.exe" or "clojure-lsp")
    end,
}
