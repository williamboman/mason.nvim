const VERSION = "v3.2.0";

const platform = os.platform();

const target = (() => {
    switch (platform) {
        case "darwin":
            return `https://github.com/latex-lsp/texlab/releases/download/${VERSION}/texlab-x86_64-macos.tar.gz`;
        default:
            return `https://github.com/latex-lsp/texlab/releases/download/${VERSION}/texlab-x86_64-linux.tar.gz`;
    }
})();

await $`wget -O texlab.tar.gz ${target}`;
await $`tar xf texlab.tar.gz`;
await $`rm texlab.tar.gz`;
