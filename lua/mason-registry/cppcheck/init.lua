local Pkg = require "mason-core.package"
local Optional = require "mason-core.optional"
local git = require "mason-core.managers.git"
local github = require "mason-core.managers.github"

return Pkg.new {
	name = "cppcheck",
	desc = [[ Cppcheck is an analysis tool for C/C++ code. It detects the types of bugs that the compilers normally fail to detect. The goal is no false positives. ]],
	homepage = "https://cppcheck.sourceforge.io/",
	languages = { Pkg.Lang.C, Pkg.Lang["C++"] },
	categories = { Pkg.Cat.Linter },
	---@async
	---@param ctx InstallContext
	install = function(ctx)
		local source = github.tag { repo = "danmar/cppcheck" }
		source.with_receipt()
		git.clone {
			"https://github.com/danmar/cppcheck.git",
			version = Optional.of(source.tag),
		}
		source.with_receipt()
		ctx.spawn["make"] { "MATCHCOMPILER=yes", "HAVE_RULES=yes", "CXXFLAGS=-O2 -DNDEBUG" }
		ctx:link_bin("cppcheck", "cppcheck")
	end,
}
