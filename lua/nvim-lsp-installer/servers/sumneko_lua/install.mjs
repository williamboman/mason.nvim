await $`git clone --depth 1 https://github.com/sumneko/lua-language-server.git .`;
await $`git submodule update --init --recursive`;

cd("3rd/luamake");
switch (os.platform()) {
    case "darwin": {
        await $`ninja -f compile/ninja/macos.ninja`;
        break;
    }
    default: {
        await $`ninja -f compile/ninja/linux.ninja`;
        break;
    }
}

cd(".");
await $`./3rd/luamake/luamake rebuild &> /dev/null`;
