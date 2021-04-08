local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('c-family')

local install_cmd = [=[
if [[ $(uname) == Linux ]]; then
  wget -O clangd.zip https://github.com/clangd/clangd/releases/download/11.0.0/clangd-linux-11.0.0.zip;
elif [[ $(uname) == Darwin ]]; then 
  wget -O clangd.zip https://github.com/clangd/clangd/releases/download/11.0.0/clangd-mac-11.0.0.zip; 
else 
  >&2 echo "$(uname) not supported."; 
  exit 1;
fi

unzip clangd.zip; 
rm clangd.zip;
mv clangd_11.0.0 clangd;

]=]

return server.Server:new {
  name = "clangd",
  root_dir = root_dir, 
  install_cmd = install_cmd, 
  default_options = {
    cmd = { root_dir .. '/clangd/bin/clangd'},
  }
}
