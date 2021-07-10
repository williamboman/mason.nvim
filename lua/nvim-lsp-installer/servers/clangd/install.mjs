const VERSION = "12.0.0";

const target = (() => {
    const platform = os.platform();
    switch (platform) {
        case "win32": {
            console.error(chalk.red(`${platform} is not yet supported.`));
            process.exit(1);
        }
        case "darwin":
            return `clangd-mac-${VERSION}.zip`;
        default:
            return `clangd-linux-${VERSION}.zip`;
    }
})();

const downloadUrl = `https://github.com/clangd/clangd/releases/download/${VERSION}/${target}`;

await $`wget -O clangd.zip ${downloadUrl}`;
await $`unzip clangd.zip`;
await $`rm clangd.zip`;
await $`mv clangd_${VERSION} clangd`;
