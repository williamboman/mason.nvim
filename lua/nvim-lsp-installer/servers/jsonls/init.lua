local create_server = require "nvim-lsp-installer.servers.vscode-langservers-extracted"

return create_server("jsonls", "vscode-json-language-server")
