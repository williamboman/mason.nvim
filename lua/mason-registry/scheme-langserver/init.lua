local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
  name = "scheme-langserver",
  desc = [[R6RS scheme language server protocol implementation]],
  homepage = "https://github.com/ufo5260987423/scheme-langserver",
  languages = { Pkg.Lang.scheme },
  categories = { Pkg.Cat.LSP },
  ---@async
  ---@param ctx InstallContext
  install = function(ctx)
    local repo = "ufo5260987423/scheme-langserver"

    platform.when {
      unix = function()
        github
            .download_release_file({
              repo = repo,
              out_file = platform.is.win and "scheme-langserver.exe" or "scheme-langserver",
              asset_file = coalesce(
              -- when(platform.is.mac_x64, format_release_file "scheme-langserver_%s_darwin_amd64.tar.gz"),
              -- when(platform.is.mac_arm64, format_release_file "scheme-langserver_%s_darwin_arm64.tar.gz"),
                when(platform.is.linux_x64, "run")
              -- ,
              -- when(platform.is.linux_arm, format_release_file "scheme-langserver_%s_linux_armv6.tar.gz"),
              -- when(platform.is.linux_arm64, format_release_file "scheme-langserver_%s_linux_arm64.tar.gz"),
              -- when(platform.is.linux_x86, format_release_file "scheme-langserver_%s_linux_386.tar.gz")
              )
            })
            .with_receipt()
        std.chmod("+x", { "scheme-langserver" })
      end
      -- ,
      -- win = function()
      --   github
      --       .unzip_release_file({
      --         repo = repo,
      --         asset_file = coalesce(
      --           when(platform.is.win_arm64, format_release_file "scheme-langserver_%s_windows_arm64.zip"),
      --           when(platform.is.win_x64, format_release_file "scheme-langserver_%s_windows_amd64.zip"),
      --           when(platform.is.win_x86, format_release_file "scheme-langserver_%s_windows_386.zip")
      --         ),
      --       })
      --       .with_receipt()
      -- end,
    }
    ctx:link_bin("scheme-langserver", platform.is.win and "scheme-langserver.exe" or "scheme-langserver")
  end,
}
