const VERSION = "v3.2.0"

const platform = os.platform();

const target = (() => {
    switch (platform) {
        case "darwin":
            return `https://github.com/latex-lsp/texlab/releases/download/${VERSION}/texlab-x86_64-macos.tar.gz`;
        case "win32": {
            console.error(chalk.red("Windows is currently not supported."));
            process.exit(1);
            break;
        }
        default:
            return `https://github.com/latex-lsp/texlab/releases/download/${VERSION}/texlab-x86_64-linux.tar.gz`;
    }
})();

await $`wget -O texlab.tar.gz ${target}`
await $`tar xf texlab.tar.gz`
await $`rm texlab.tar.gz`
