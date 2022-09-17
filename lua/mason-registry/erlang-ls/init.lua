local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local std = require "mason-core.managers.std"
local git = require "mason-core.managers.git"
local github = require "mason-core.managers.github"
local Optional = require "mason-core.optional"
local path = require "mason-core.path"

local rebar3 = platform.is.win and "rebar3.cmd" or "rebar3"

return Pkg.new {
    name = "erlang-ls",
    desc = _.dedent [[
        Implementing features such as auto-complete or go-to-definition for a programming language is not trivial.
        Traditionally, this work had to be repeated for each development tool and it required a mix of expertise in both
        the targeted programming language and the programming language internally used by the development tool of
        choice.
    ]],
    languages = { Pkg.Lang.Erlang },
    categories = { Pkg.Cat.LSP },
    homepage = "https://erlang-ls.github.io/",
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        std.ensure_executable(rebar3, { help_url = "http://rebar3.org/docs/" })

        local repo = "erlang-ls/erlang_ls"
        local source = github.tag { repo = repo }
        source.with_receipt()
        git.clone { ("https://github.com/%s.git"):format(repo), version = Optional.of(source.tag) }

        ctx.spawn[rebar3] { "escriptize" }
        ctx.spawn[rebar3] { "as", "dap", "escriptize" }
        ctx:link_bin(
            "erlang_ls",
            path.concat { "_build", "default", "bin", platform.is.win and "erlang_ls.bat" or "erlang_ls" }
        )
    end,
}
