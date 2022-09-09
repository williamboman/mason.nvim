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
  bash = { "bash-debug-adapter", "bash-language-server", "shellcheck", "shellharden", "shfmt" },
  bazel = { "buildifier" },
  beancount = { "beancount-language-server" },
  bicep = { "bicep-lsp" },
  blade = { "blade-formatter" },
  c = { "clang-format", "clangd", "codelldb", "cpplint", "cpptools" },
  ["c#"] = { "clang-format", "csharp-language-server", "csharpier", "netcoredbg", "omnisharp", "omnisharp-mono" },
  ["c++"] = { "clang-format", "clangd", "codelldb", "cpplint", "cpptools" },
  clarity = { "clarity-lsp" },
  clojure = { "clojure-lsp", "joker" },
  clojurescript = { "clojure-lsp", "joker" },
  cmake = { "cmake-language-server", "cmakelang" },
  codeql = { "codeql" },
  crystal = { "crystalline" },
  css = { "css-lsp", "cssmodules-language-server", "prettier", "prettierd", "tailwindcss-language-server" },
  cucumber = { "cucumber-language-server" },
  cue = { "cuelsp" },
  d = { "serve-d" },
  dhall = { "dhall-lsp" },
  django = { "curlylint", "djlint" },
  dockerfile = { "dockerfile-language-server", "hadolint" },
  dot = { "dot-language-server" },
  elixir = { "elixir-ls" },
  elm = { "elm-format", "elm-language-server" },
  ember = { "ember-language-server" },
  emmet = { "emmet-ls" },
  erlang = { "erlang-ls" },
  ["f#"] = { "fantomas", "fsautocomplete", "netcoredbg" },
  flow = { "prettier", "prettierd" },
  flux = { "flux-lsp" },
  fortran = { "fortls" },
  gitcommit = { "gitlint" },
  go = { "delve", "djlint", "go-debug-adapter", "gofumpt", "goimports", "golangci-lint", "golangci-lint-langserver", "golines", "gomodifytags", "gopls", "gotests", "impl", "json-to-struct", "revive", "staticcheck" },
  graphql = { "graphql-language-service-cli", "prettier", "prettierd" },
  groovy = { "groovy-language-server" },
  haml = { "haml-lint" },
  handlebargs = { "djlint" },
  haskell = { "haskell-language-server" },
  haxe = { "haxe-language-server" },
  hoon = { "hoon-language-server" },
  html = { "erb-lint", "html-lsp", "prettier", "prettierd" },
  java = { "clang-format", "jdtls" },
  javascript = { "chrome-debug-adapter", "clang-format", "deno", "eslint-lsp", "eslint_d", "firefox-debug-adapter", "node-debug2-adapter", "prettier", "prettierd", "quick-lint-js", "rome", "typescript-language-server", "xo" },
  jinja = { "curlylint", "djlint" },
  json = { "cfn-lint", "clang-format", "fixjson", "jq", "json-lsp", "prettier", "prettierd", "spectral-language-server" },
  jsonnet = { "jsonnet-language-server" },
  jsx = { "prettier", "prettierd" },
  julia = { "julia-lsp" },
  kotlin = { "kotlin-language-server", "ktlint" },
  latex = { "ltex-ls", "tectonic", "texlab", "vale" },
  lelwel = { "lelwel" },
  less = { "css-lsp", "prettier", "prettierd" },
  liquid = { "curlylint", "shopify-theme-check" },
  lua = { "lemmy-help", "lua-language-server", "luacheck", "luaformatter", "selene", "stylua" },
  luau = { "luau-lsp" },
  markdown = { "alex", "cbfmt", "grammarly-languageserver", "ltex-ls", "markdownlint", "marksman", "prettier", "prettierd", "proselint", "prosemd-lsp", "remark-language-server", "textlint", "vale", "write-good", "zk" },
  ["metamath zero"] = { "metamath-zero-lsp" },
  mksh = { "shfmt" },
  mustache = { "djlint" },
  nickel = { "nickel-lang-lsp" },
  nim = { "nimlsp" },
  nix = { "rnix-lsp" },
  nunjucks = { "curlylint", "djlint" },
  ocaml = { "ocaml-lsp" },
  onescript = { "bsl-language-server" },
  opencl = { "opencl-language-server" },
  openfoam = { "foam-language-server" },
  perl = { "perlnavigator" },
  php = { "intelephense", "php-cs-fixer", "php-debug-adapter", "phpactor", "phpcbf", "phpcs", "phpmd", "phpstan", "psalm" },
  powershell = { "powershell-editor-services" },
  prisma = { "prisma-language-server" },
  protobuf = { "buf", "buf-language-server" },
  puppet = { "puppet-editor-services" },
  purescript = { "purescript-language-server" },
  python = { "autopep8", "black", "blue", "debugpy", "flake8", "isort", "jedi-language-server", "mypy", "pylint", "pyright", "python-lsp-server", "sourcery", "vulture", "yapf" },
  r = { "r-languageserver" },
  reason = { "reason-language-server" },
  rescript = { "rescript-lsp" },
  ["robot framework"] = { "robotframework-lsp" },
  ruby = { "erb-lint", "rubocop", "solargraph", "sorbet", "standardrb" },
  rust = { "codelldb", "cpptools", "rust-analyzer" },
  salt = { "salt-lsp" },
  scss = { "css-lsp", "prettier", "prettierd" },
  shell = { "shfmt" },
  slint = { "slint-lsp" },
  solidity = { "solang", "solhint", "solidity" },
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
  typescript = { "chrome-debug-adapter", "deno", "eslint-lsp", "eslint_d", "firefox-debug-adapter", "node-debug2-adapter", "prettier", "prettierd", "rome", "typescript-language-server", "xo" },
  v = { "vls" },
  vala = { "vala-language-server" },
  vimscript = { "vim-language-server", "vint" },
  visualforce = { "visualforce-language-server" },
  vue = { "prettier", "prettierd", "vetur-vls", "vue-language-server" },
  wgsl = { "wgsl-analyzer" },
  xml = { "lemminx", "xmlformatter" },
  yaml = { "actionlint", "cfn-lint", "prettier", "prettierd", "spectral-language-server", "yaml-language-server", "yamlfmt", "yamllint" },
  zig = { "zls" }
}