local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('ruby')

local install_cmd = [[
wget -O solargraph.tar $(curl -s https://api.github.com/repos/castwide/solargraph/tags | grep 'tarball_url' | cut -d\" -f4 | head -n1);
rm -rf solargraph;
mkdir solargraph;
tar -xzf solargraph.tar -C solargraph --strip-components 1;
rm solargraph.tar;
cd solargraph;

bundle install --without development --path vendor/bundle;

echo '#!/usr/bin/env bash' > solargraph;
echo 'cd "$(dirname "$0")" || exit' >> solargraph;
echo 'bundle exec solargraph $*' >> solargraph;

chmod +x solargraph;
]]

return server.Server:new {
    name = "solargraph",
    root_dir = root_dir,
    install_cmd = install_cmd,
    pre_install_check = function ()
        if vim.fn.executable('bundle') ~= 1 then
            error("bundle not installed")
        end
    end,
    default_options = {
        cmd = { root_dir .. '/solargraph/solargraph', 'stdio' },
    }
}
