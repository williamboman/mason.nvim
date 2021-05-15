local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('latex')

local install_cmd = [=[
if [[ $(uname) == Linux ]]; then
  wget -O texlab.tar.gz https://github.com/latex-lsp/texlab/releases/download/v2.2.2/texlab-x86_64-linux.tar.gz
elif [[ $(uname) == Darwin ]]; then 
  wget -O texlab.tar.gz https://github.com/latex-lsp/texlab/releases/download/v2.2.2/texlab-x86_64-macos.tar.gz
else 
  >&2 echo "$(uname) not supported."; 
  exit 1;
fi

tar xf texlab.tar.gz

]=]

return server.Server:new {
  name = "texlab", 
  root_dir = root_dir, 
  install_cmd = install_cmd, 
  pre_install_check = function ()
    if vim.fn.executable("wget") ~=1 then 
      error("Missing wget. Please, refer to https://www.gnu.org/software/wget/ to install it.")
    elseif vim.fn.executable("pdflatex") ~=1 then
      error("The program pdflatex wasn't found. Please install a TeX distribution: https://www.latex-project.org/get/#tex-distributions")
    end
  end,
  default_options = {
    cmd = {root_dir .. '/texlab'},
  }
}
