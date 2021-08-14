local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local zx = require "nvim-lsp-installer.installers.zx"

local root_dir = server.get_server_root_path "latex"

return server.Server:new {
    name = "texlab",
    root_dir = root_dir,
    installer = zx.file "./install.mjs",
    pre_install_check = function()
        if vim.fn.executable "wget" ~= 1 then
            error "Missing wget. Please, refer to https://www.gnu.org/software/wget/ to install it."
        elseif vim.fn.executable "pdflatex" ~= 1 then
            error "The program pdflatex wasn't found. Please install a TeX distribution: https://www.latex-project.org/get/#tex-distributions"
        end
    end,
    default_options = {
        cmd = { path.concat { root_dir, "texlab" } },
    },
}
