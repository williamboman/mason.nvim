-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
-- stylua: ignore start
return {
  [".net"] = { "netcoredbg" },
  ["1С:enterprise"] = { "bsl-language-server" },
  ada = { "ada-language-server" },
  angular = { "angular-language-server", "djlint", "prettier", "prettierd" },
  ansible = { "ansible-language-server" },
  apex = { "apex-language-server" },
  arduino = { "arduino-language-server" },
  assembly = { "asm-lsp" },
  astro = { "astro-language-server" },
  awk = { "awk-language-server" },
  bash = { "bash-debug-adapter", "bash-language-server", "beautysh", "shellcheck", "shellharden", "shfmt" },
  bazel = { "buildifier" },
  beancount = { "beancount-language-server" },
  bicep = { "bicep-lsp" },
  blade = { "blade-formatter" },
  c = { "clang-format", "clangd", "codelldb", "cpplint", "cpptools" },
  ["c#"] = { "clang-format", "csharp-language-server", "csharpier", "netcoredbg", "omnisharp", "omnisharp-mono", "semgrep" },
  ["c++"] = { "clang-format", "clangd", "codelldb", "cpplint", "cpptools" },
  clarity = { "clarity-lsp" },
  clojure = { "clojure-lsp", "joker" },
  clojurescript = { "clojure-lsp", "joker" },
  cmake = { "cmake-language-server", "cmakelang", "gersemi", "neocmakelsp" },
  codeql = { "codeql" },
  crystal = { "crystalline" },
  csh = { "beautysh" },
  css = { "css-lsp", "cssmodules-language-server", "prettier", "prettierd", "tailwindcss-language-server" },
  cucumber = { "cucumber-language-server" },
  cue = { "cueimports", "cuelsp" },
  d = { "serve-d" },
  dart = { "dart-debug-adapter" },
  dhall = { "dhall-lsp" },
  django = { "curlylint", "djlint" },
  dockerfile = { "dockerfile-language-server", "hadolint" },
  dot = { "dot-language-server" },
  elixir = { "elixir-ls" },
  elm = { "elm-format", "elm-language-server" },
  ember = { "ember-language-server" },
  emmet = { "emmet-ls" },
  erg = { "erg-language-server" },
  erlang = { "erlang-ls" },
  ["f#"] = { "fantomas", "fsautocomplete", "netcoredbg" },
  flow = { "prettier", "prettierd" },
  flux = { "flux-lsp" },
  fortran = { "fortls" },
  gitcommit = { "commitlint", "gitlint" },
  glimmer = { "glint" },
  go = { "delve", "djlint", "go-debug-adapter", "gofumpt", "goimports", "goimports-reviser", "golangci-lint", "golangci-lint-langserver", "golines", "gomodifytags", "gopls", "gotests", "gotestsum", "iferr", "impl", "json-to-struct", "revive", "semgrep", "staticcheck" },
  gradle = { "gradle-language-server" },
  graphql = { "graphql-language-service-cli", "prettier", "prettierd" },
  groovy = { "groovy-language-server" },
  haml = { "haml-lint" },
  handlebargs = { "djlint" },
  handlebars = { "glint" },
  haskell = { "fourmolu", "haskell-language-server" },
  haxe = { "haxe-language-server" },
  hoon = { "hoon-language-server" },
  html = { "erb-lint", "html-lsp", "prettier", "prettierd" },
  java = { "clang-format", "java-debug-adapter", "java-test", "jdtls", "semgrep" },
  javascript = { "chrome-debug-adapter", "clang-format", "deno", "eslint-lsp", "eslint_d", "firefox-debug-adapter", "glint", "js-debug-adapter", "node-debug2-adapter", "prettier", "prettierd", "quick-lint-js", "rome", "semgrep", "typescript-language-server", "xo" },
  jinja = { "curlylint", "djlint" },
  jq = { "jq-lsp" },
  json = { "cfn-lint", "clang-format", "fixjson", "jq", "json-lsp", "jsonlint", "nxls", "prettier", "prettierd", "semgrep", "spectral-language-server" },
  jsonnet = { "jsonnet-language-server" },
  jsx = { "prettier", "prettierd" },
  julia = { "julia-lsp" },
  kotlin = { "kotlin-debug-adapter", "kotlin-language-server", "ktlint" },
  ksh = { "beautysh" },
  latex = { "ltex-ls", "tectonic", "texlab", "vale" },
  lelwel = { "lelwel" },
  less = { "css-lsp", "prettier", "prettierd" },
  liquid = { "curlylint", "shopify-theme-check" },
  lua = { "lemmy-help", "lua-language-server", "luacheck", "luaformatter", "selene", "stylua" },
  luau = { "luau-lsp", "selene", "stylua" },
  markdown = { "alex", "cbfmt", "glow", "grammarly-languageserver", "ltex-ls", "markdownlint", "marksman", "prettier", "prettierd", "proselint", "prosemd-lsp", "remark-cli", "remark-language-server", "textlint", "vale", "write-good", "zk" },
  ["metamath zero"] = { "metamath-zero-lsp" },
  mksh = { "shfmt" },
  move = { "move-analyzer" },
  mustache = { "djlint" },
  nginx = { "nginx-language-server" },
  nickel = { "nickel-lang-lsp" },
  nim = { "nimlsp" },
  nix = { "nil", "rnix-lsp" },
  nunjucks = { "curlylint", "djlint" },
  ocaml = { "ocaml-lsp", "ocamlformat" },
  onescript = { "bsl-language-server" },
  opencl = { "opencl-language-server" },
  openfoam = { "foam-language-server" },
  openscad = { "openscad-lsp" },
  perl = { "perlnavigator" },
  php = { "intelephense", "php-cs-fixer", "php-debug-adapter", "phpactor", "phpcbf", "phpcs", "phpmd", "phpstan", "pint", "psalm", "semgrep" },
  powershell = { "powershell-editor-services" },
  prisma = { "prisma-language-server" },
  protobuf = { "buf", "buf-language-server", "protolint" },
  puppet = { "puppet-editor-services" },
  purescript = { "purescript-language-server" },
  python = { "autoflake", "autopep8", "black", "blue", "debugpy", "flake8", "isort", "jedi-language-server", "mypy", "pydocstyle", "pylama", "pylint", "pyproject-flake8", "pyre", "pyright", "python-lsp-server", "reorder-python-imports", "rstcheck", "ruff", "ruff-lsp", "semgrep", "sourcery", "usort", "vulture", "yapf" },
  r = { "r-languageserver" },
  raku = { "raku-navigator" },
  reason = { "reason-language-server" },
  rescript = { "rescript-lsp" },
  ["robot framework"] = { "robotframework-lsp" },
  ruby = { "erb-lint", "rubocop", "ruby-lsp", "semgrep", "solargraph", "sorbet", "standardrb" },
  rust = { "codelldb", "cpptools", "rust-analyzer", "rustfmt" },
  salt = { "salt-lsp" },
  scala = { "semgrep" },
  scss = { "css-lsp", "prettier", "prettierd" },
  sh = { "beautysh" },
  shell = { "shfmt" },
  slint = { "slint-lsp" },
  smithy = { "smithy-language-server" },
  solidity = { "solang", "solhint", "solidity", "solidity-ls" },
  sphinx = { "esbonio" },
  sql = { "sql-formatter", "sqlfluff", "sqlls", "sqls" },
  stylelint = { "stylelint-lsp" },
  svelte = { "svelte-language-server" },
  systemverilog = { "svlangserver", "svls", "verible" },
  teal = { "teal-language-server" },
  terraform = { "terraform-ls", "tflint" },
  text = { "grammarly-languageserver", "ltex-ls", "proselint", "textlint", "vale" },
  toml = { "taplo" },
  twig = { "curlylint", "twigcs" },
  typescript = { "chrome-debug-adapter", "deno", "eslint-lsp", "eslint_d", "firefox-debug-adapter", "glint", "js-debug-adapter", "node-debug2-adapter", "prettier", "prettierd", "rome", "semgrep", "typescript-language-server", "xo" },
  v = { "vls" },
  vala = { "vala-language-server" },
  vimscript = { "vim-language-server", "vint" },
  visualforce = { "visualforce-language-server" },
  vue = { "prettier", "prettierd", "vetur-vls", "vue-language-server" },
  wgsl = { "wgsl-analyzer" },
  xml = { "lemminx", "xmlformatter" },
  yaml = { "actionlint", "cfn-lint", "prettier", "prettierd", "spectral-language-server", "yaml-language-server", "yamlfmt", "yamllint" },
  zig = { "zls" },
  zsh = { "beautysh" }
}